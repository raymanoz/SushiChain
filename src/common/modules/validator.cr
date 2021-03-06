# Copyright © 2017-2018 The SushiChain Core developers
#
# See the LICENSE file at the top-level directory of this distribution
# for licensing information.
#
# Unless otherwise agreed in a custom licensing agreement with the SushiChain Core developers,
# no part of this software, including this file, may be copied, modified,
# propagated, or distributed except according to the terms contained in the
# LICENSE file.
#
# Removal or modification of this copyright notice is prohibited.

module ::Sushi::Common::Validator
  def valid_amount?(amount : Int64) : Bool
    if Int64::MAX < amount || 0 > amount
      raise "the amount is out of range"
    end

    true
  end

  def valid_amount?(amount : String) : Bool
    amount_decimal = BigDecimal.new(amount)

    if BigDecimal.new(Int64::MAX, Denomination::SCALE_DECIMAL) < amount_decimal || 0 > amount_decimal
      raise "the amount is out of range"
    end

    true
  end
end
