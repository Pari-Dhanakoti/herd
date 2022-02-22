defmodule Herd.Supervisor do
  @moduledoc """
  Creates a Supervisor for the herd's internal registry, it's pool of pools,
  and the cluster.  Use with:

  ```
  defmodule MyHerdSupervisor do
    use Herd.Supervisor, otp_app: :my_app,
                         cluster: MyCluster,
                         pool: MyPool
  end
  """
  defmacro __using__(opts) do
    app     = Keyword.get(opts, :otp_app)
    pool    = Keyword.get(opts, :pool)
    cluster = Keyword.get(opts, :cluster)
    quote do
      use Supervisor
      @otp unquote(app)
      @pool unquote(pool)
      @cluster unquote(cluster)


      def start_link(options) do
        Supervisor.start_link(__MODULE__, options, name: __MODULE__)
      end

      def init(options) do
        opts = Keyword.put(supervisor_config(), :strategy, :one_for_one)

        children = [
          # needs to be started FIRST
          {Registry, keys: :unique, name: Module.concat(@pool, Registry)},
          {@pool, [options]},
          {@cluster, [options]}
        ]

        Supervisor.init(children, strategy: :one_for_one)
      end

      def supervisor_config(), do: Application.get_env(@otp, __MODULE__, [])
    end
  end
end
