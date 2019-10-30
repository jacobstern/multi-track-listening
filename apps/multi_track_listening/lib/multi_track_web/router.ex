defmodule MultiTrackWeb.Router do
  use MultiTrackWeb, :router
  use Pow.Phoenix.Router

  alias MultiTrackWeb.Plugs.{RedirectToPublishedMix, LoadMix}

  pipeline :protected do
    plug Pow.Plug.RequireAuthenticated,
      error_handler: Pow.Phoenix.PlugErrorHandler
  end

  pipeline :browser do
    if Mix.env() == :prod do
      plug Plug.SSL, rewrite_on: [:x_forwarded_proto]
    end

    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    if Mix.env() == :prod do
      plug Plug.SSL, rewrite_on: [:x_forwarded_proto]
    end

    plug :accepts, ["json"]
  end

  pipeline :mix_common do
    plug LoadMix
    plug RedirectToPublishedMix
  end

  scope "/" do
    pipe_through :browser

    pow_routes()
  end

  scope "/", MultiTrackWeb do
    pipe_through :browser

    get "/", HomeController, :index

    get "/uploads/:uuid", StorageController, :serve_file

    post "/mixes/create", MixController, :create

    scope "/mixes" do
      pipe_through :mix_common

      get "/:id/track-one", MixController, :new_track_one
      post "/:id/track-one", MixController, :create_track_one
      get "/:id/track-two", MixController, :new_track_two
      post "/:id/track-two", MixController, :create_track_two
      get "/:id/parameters", MixController, :parameters
      put "/:id/parameters", MixController, :create_mix_render
      get "/:id/renders/:render_id", MixController, :mix_render
      post "/:id/renders/:render_id/publish", MixController, :publish
    end

    get "/published/anonymous/:id", PublishedMixController, :show
  end

  scope "/health", MultiTrackWeb do
    get "/", HealthController, :index
  end
end
