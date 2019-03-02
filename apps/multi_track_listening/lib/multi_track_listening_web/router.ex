defmodule MultiTrackWeb.Router do
  use MultiTrackWeb, :router

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

  scope "/", MultiTrackWeb do
    pipe_through :browser

    get "/", HomeController, :index

    get "/uploads/:uuid", StorageController, :serve_file

    post "/mixes/create", MixController, :create
    get "/mixes/:id/track-one", MixController, :new_track_one
    post "/mixes/:id/track-one", MixController, :create_track_one
    get "/mixes/:id/track-two", MixController, :new_track_two
    post "/mixes/:id/track-two", MixController, :create_track_two
    get "/mixes/:id/parameters", MixController, :parameters
    put "/mixes/:id/parameters", MixController, :create_mix_render
    get "/mixes/:id/renders/:render_id", MixController, :mix_render
  end

  # Other scopes may use custom stacks.
  # scope "/api", MultiTrackWeb do
  #   pipe_through :api
  # end
end
