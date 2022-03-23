defmodule ProxusUiWeb.DashboardLive do
  require Logger

  use ProxusUiWeb, :live_view

  @bedroom_led "bedroom-led-lights"

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    state = ProxusUi.LedChip.get_state(@bedroom_led)

    if connected?(socket) do
      ProxusUi.LedChip.subscribe(state.mdns)
    end

    {:ok,
       socket
       |> assign(:page_title, "Proxus Dashboard")
       |> assign(:bedroom_led, state)}
  end

  @impl Phoenix.LiveView
  def handle_event("change-brightness", %{"brightness" => %{"brightness" => brightness}}, socket) do
    bedroom_led = socket.assigns.bedroom_led

    if bedroom_led.current_brightness !== brightness do
      Logger.debug("[DashboardLive] Brightness changed, setting #{bedroom_led.mdns} to #{brightness}")

      bedroom_led = ProxusUi.LedChip.set_current_brightness(bedroom_led, brightness)

      {:noreply, assign(socket, :bedroom_led, bedroom_led)}
    else
      {:noreply, socket}
    end
  end


  @impl Phoenix.LiveView
  def handle_event("change-colour", %{"colour" => %{"colour" => colour}}, socket) do
    bedroom_led = socket.assigns.bedroom_led

    if bedroom_led.current_colour !== colour do
      Logger.debug("[DashboardLive] Colour changed, setting #{bedroom_led.mdns} to #{colour}")

      bedroom_led = ProxusUi.LedChip.set_current_colour(bedroom_led, colour)

      {:noreply, assign(socket, :bedroom_led, bedroom_led)}
    else
      {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:update_led_state, new_state}, socket) do
    {:noreply, assign(socket, :bedroom_led, new_state)}
  end
end

