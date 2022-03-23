defmodule ProxusUi.LedChip do
  require Logger

  use GenServer

  alias ProxusUi.LedChip.Communicator

  defmodule State do
    @enforce_keys [:mdns]
    defstruct @enforce_keys ++ [
      current_colour: "Unknown",
      current_brightness: "Unknown",
      sunrise_time: "Unknown",
      time_zone: "Unknown",
      current_sunrise_duration: "Unknown",
      version: "Unknown",
      time: "Unknown",
      connection_status: "Disconnected",
      wifi_strength: "Disconnected"
    ]

    def set_disconnected(state) do
      %{state | connection_status: "Disconnected", wifi_strength: "Disconnected"}
    end

    def set_connected(state, wifi_strength) do
      %{state | connection_status: "Connected", wifi_strength: wifi_strength}
    end
  end

  @check_interval :timer.seconds(1)

  def start_link(mdns, opts \\ []) do
    opts = Keyword.put_new(opts, :name, server_name(mdns))

    GenServer.start_link(ProxusUi.LedChip, mdns, opts)
  end

  defp server_name(mdns) do
    :"#{mdns}_led_chip"
  end

  def init(mdns) do
    {:ok, %State{mdns: mdns}, {:continue, mdns}}
  end

  def get_state(mdns) do
    :sys.get_state(server_name(mdns))
  end

  def subscribe(mdns) do
    Phoenix.PubSub.subscribe(ProxusUi.PubSub, event_name(mdns))
  end

  defp event_name(mdns) do
    "led:#{mdns}:update"
  end

  def set_current_colour(led_chip, colour) do
    case Communicator.update_colour(led_chip.mdns, colour) do
      {:ok, _} -> %{led_chip | current_colour: colour}
      {:error, e} ->
        Logger.error("[LedChip] Error updating colour #{inspect e}")

        led_chip
    end
  end

  def set_current_brightness(led_chip, brightness) do
    case Communicator.update_brightness(led_chip.mdns, brightness) do
      {:ok, _} -> %{led_chip | current_brightness: brightness}
      {:error, e} ->
        Logger.error("[LedChip] Error updating brightness #{inspect e}")

        led_chip
    end
  end

  def handle_continue(_mdns, state) do
    Task.Supervisor.async_nolink(Task.LedChipSupervisor, fn ->
      {:update_state, Communicator.update_settings(state)}
    end)

    {:noreply, state}
  end

  def handle_info(:recheck_state, state) do
    Task.Supervisor.async_nolink(Task.LedChipSupervisor, fn ->
      {:update_state, Communicator.update_settings(state)}
    end)

    {:noreply, state}
  end

  def handle_info({_ref, {:update_state, new_state}}, old_state) do
    Process.send_after(self(), :recheck_state, @check_interval)

    if new_state !== old_state do
      Logger.debug("[LedChip] State changed, broadcasting #{event_name(new_state.mdns)}\n#{inspect new_state}")
      Phoenix.PubSub.broadcast!(ProxusUi.PubSub, event_name(new_state.mdns), {:update_led_state, new_state})
    end

    {:noreply, new_state}
  end

  def handle_info({:DOWN, _ref, :process, _pid, :normal}, state) do
    {:noreply, state}
  end
end
