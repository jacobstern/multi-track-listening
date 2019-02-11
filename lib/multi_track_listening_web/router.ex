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
    get "/mixes/:id/upload-second-track", MixController, :new_track_two
  end

  # Other scopes may use custom stacks.
  # scope "/api", MultiTrackListeningWeb do
  #   pipe_through :api
  # end
end
