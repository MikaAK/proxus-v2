defmodule ProxusUiWeb.PageController do
  use ProxusUiWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
