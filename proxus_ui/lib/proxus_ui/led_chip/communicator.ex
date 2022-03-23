defmodule ProxusUi.LedChip.Communicator do
  require Logger

  alias ProxusUi.LedChip

  def update_settings(%LedChip.State{mdns: mdns} = led_chip) do
    case query_led_chip(mdns, "settings", nil) do
      {:ok, body} ->
        Logger.debug("[LedChip.Communicator] Connected to #{mdns}, merging settings into state...")
        merge_settings_into_chip(led_chip, Jason.decode!(body))

      {:error, e} ->
        Logger.error("[LedChip.Communicator] #{inspect e}")

        LedChip.State.set_disconnected(led_chip)
    end
  end

  defp merge_settings_into_chip(led_chip, params) do
    LedChip.State.set_connected(%{led_chip |
      current_colour: "##{Integer.to_string(params["currentColor"], 16)}",
      current_brightness: params["currentBrightness"],
      current_sunrise_duration: params["currentSunriseDuration"],
      sunrise_time: params["sunriseTime"],
      version: params["version"],
      time: params["time"],
      time_zone: params["timeZone"],
    }, params["wifiStrength"])
  end

  def update_colour(mdns, colour) do
    colour = String.replace(colour, "#", "")

    query_led_chip(mdns, "set-color", %{value: colour})
  end

  def update_brightness(mdns, brightness) do
    query_led_chip(mdns, "set-brightness", %{value: brightness})
  end

  defp query_led_chip(mdns, device_method, params) do
    case http_get(build_url(mdns, device_method, params)) do
      {:ok, %Finch.Response{status: 200, body: body}} -> {:ok, body}
      {:ok, %Finch.Response{status: status, body: body}} -> {:error, %{code: status, message: body}}
      {:error, %Mint.TransportError{reason: :nxdomain}} -> {:error, "Cannot connect to led chip on #{mdns}.local"}
      e -> e
    end
  end

  defp build_url(mdns, device_method, nil) do
    "http://#{mdns}.local/#{device_method}"
  end

  defp build_url(mdns, device_method, params) do
    "#{build_url(mdns, device_method, nil)}?#{URI.encode_query(params)}"
  end

  defp http_get(url) do
    :get |> Finch.build(url) |> Finch.request(LedFinch)
  end
end

