defmodule Herd.Supervisor do
  @moduledoc """
  Creates a Supervisor for the herd's internal registry, it's pool of pools,
  and the cluster.  Use with:

  ```
  defmodule MyHerdSupervisor do
    use Herd.Supervisor, otp_app: :my_app, herd: :my_herd
  end
  """
  defmacro __using__(opts) do
    app   = Keyword.get(opts, :otp_app)
    herd = Keyword.get(opts, :herd)
    quote do
      use Supervisor
      @otp unquote(app)
      @herd unquote(herd)
      @herd Application.get_env(@otp, @herd)
      @pool @herd[:pool]
      @cluster @herd[:cluster]

      @supervisor_config Application.get_env(@otp, __MODULE__, [])

      def start_link(options) do
        Supervisor.start_link(__MODULE__, options, name: __MODULE__)
      end

      def init(options) do
        opts = Keyword.put(@supervisor_config, :strategy, :one_for_one)

        children = [
          # needs to be started FIRST
          worker(Registry, [[name: Module.concat(@pool, Registry), keys: :unique]]),
          supervisor(@pool, [options]),
          worker(@cluster, [options]),
        ]

        supervise(children, opts)
      end
    end
  end
end