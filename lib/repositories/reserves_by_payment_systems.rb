class ReservesByPaymentSystems

  # Для резерва на главной считается баланс по агрегаторам

  def order_reservations
    # Можно вычитать все суммы по текущим заявкам
    # order_reservation.amount = order.transfer_fee + комиссия ПС
    # Order.where(status1: :open).group(:id_ps2).sum(:transfer_fee)
    @order_reservations ||= OrderReservation.joins(:wallet_to).group(:id_ps).sum(:amount)
  end

  def wallets_balances
    @wallets_balances ||= Wallet.alive.group('id_ps').sum(:balance)
  end

  def final_reserves
    @final_reserves ||= build_final_reserves
  end

  def get_reserve_by_payment_system_id(id)
    final_reserves[id] || 0
  end

  def delta
    @delta ||= build_delta
  end

  private

  def ids
    @ids ||= PaymentSystem.pluck(:id)
  end

  def build_delta
    PaymentSystem.all.each_with_object({}) { |ps, a| a[ps.id] = ps.reserves_delta_amount }
  end

  def build_final_reserves
    fr = {}

    ids.each do |id|
      value = wallets_balances[id].to_f - order_reservations[id].to_f
      value += delta[id].to_f
      value = 0 if value < 0
      fr[id] = value
    end

    aggregations.each do |agregator_id, list|
      fr[agregator_id] = list.map { |id| fr[id].to_f }.sum
    end

    fr
  end

  def aggregations
    PaymentSystem.where.not(reserves_aggregator_id: nil).
      pluck(:reserves_aggregator_id, :id).
      each_with_object({}) { |k,a| a[k.first]||=[];a[k.first]<<k.second }
  end
end
