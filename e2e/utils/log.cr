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

module ::E2E::Utils::Log
  def log_path(num : Int32, suffix : String) : String
    log_name = "#{num}_#{suffix}.log"
    File.expand_path("../../logs/#{log_name}", __FILE__)
  end
end
