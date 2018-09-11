class ReservesByCurrencies
  def order_reservations
    @order_reservations ||=
      OrderReservation.joins(:payment_system).where.not(cms_paymant_system: { type_cy: nil }).group(:type_cy).sum(:amount)
  end

  def wallets_balances
    @wallets_balances ||= Wallet.alive.joins(:payment_system).group(:type_cy).sum(:balance)
  end

  def final_reserves
    @final_reserves ||= wallets_balances.merge(order_reservations) { |k, balance, reserve| balance.to_f - reserve.to_f }
  end

  def delta
    {}
  end
end
