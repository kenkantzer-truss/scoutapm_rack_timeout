class ScoutTimeoutMiddleware
  PUMA_TIMEOUT = 10 # Heroku timeout before an H12

  class PumaTimeoutError < StandardError; end

  def initialize(app)
    @app = app
  end

  def call(env)
    request_finished = false
    start_time = Time.now.utc
    tr = ::ScoutApm::RequestManager.lookup

    Thread.new do
      begin
        loop do
          if request_finished
            break
          elsif Time.now().utc - start_time >= PUMA_TIMEOUT - 1
            raise PumaTimeoutError
            break
          else
            sleep(1)
          end
        end # loop
      rescue PumaTimeoutError => e
        tr.context.add(puma_timeout: 'true') # Add Request Context to know it was timed out
        (1..100).each do # Force-stop the TrackedRequest by stopping active layers
          tr.stop_layer
        end
        ::ScoutApm::Agent.instance.stop_background_worker
      rescue => e
        Rails.logger.warn "Exception in ScoutTimeoutMiddleware: #{e}"
      end # begin
    end

    @status, @headers, @response = @app.call(env)
    request_finished = true
    [@status, @headers, @response]
  end
end