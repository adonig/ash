defmodule Ash.Test.Support.PolicySimple.Car do
  @moduledoc false
  use Ash.Resource,
    domain: Ash.Test.Support.PolicySimple.Domain,
    data_layer: Ash.DataLayer.Ets,
    authorizers: [Ash.Policy.Authorizer]

  ets do
    private?(true)
  end

  actions do
    default_accept :*
    defaults [:read, :destroy, update: :*]

    create :create do
      primary? true
      argument(:users, {:array, :uuid})
      change(manage_relationship(:users, type: :append_and_remove))
    end

    create :authorize_unless
  end

  attributes do
    uuid_primary_key(:id)
    attribute :active, :boolean, default: true, public?: true
    timestamps()
  end

  policies do
    policy action(:authorize_unless) do
      authorize_if never()
      authorize_unless never()
      authorize_if never()
    end

    policy action_type([:update, :destroy]) do
      authorize_if expr(exists(users, id == ^actor(:id)))
    end

    policy_group action_type(:read) do
      policy do
        authorize_if expr(exists(users, id == ^actor(:id)))
      end

      policy [expr(active != true)] do
        forbid_if always()
      end
    end
  end

  relationships do
    many_to_many :users, Ash.Test.Support.PolicySimple.User do
      public?(true)
      through(Ash.Test.Support.PolicySimple.CarUser)
      source_attribute_on_join_resource(:car_id)
      destination_attribute_on_join_resource(:user_id)
    end
  end
end
