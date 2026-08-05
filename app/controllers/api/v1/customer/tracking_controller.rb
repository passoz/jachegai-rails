module Api
  module V1
    module Customer
      class TrackingController < BaseController
        def show
          tracking = CustomerTrackingService.new(Current.principal).get_tracking(params[:id])
          render_success(data: tracking)
        end
      end
    end
  end
end
