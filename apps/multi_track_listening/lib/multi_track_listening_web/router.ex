defmodule MultiTrackListeningWeb.Router do
  use MultiTrackListeningWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MultiTrackListeningWeb do
    pipe_through :browser

    get "/", HomeController, :index

    post "/mixes/create", MixController, :create
    get "/mixes/:id/track-one", MixController, :new_track_one
    post "/mixes/:id/track-one", MixController, :create_track_one
    get "/mixes/:id/track-two", MixController, :new_track_two
    post "/mixes/:id/track-two", MixController, :create_track_two
    get "/mixes/:id/finalize", MixController, :finalize
    put "/mixes/:id/finalize", MixController, :finalize_submit
    get "/mixes/:id/render-status", MixController, :render_status
  end

  # Other scopes may use custom stacks.
  # scope "/api", MultiTrackListeningWeb do
  #   pipe_through :api
  # end
end
