module ::Sushi::Interface::Sushi
  class Transaction < CLI
    def sub_actions
      [
        {
          name: "send",
          desc: "send Sushi coins to a specified address",
        },
        {
          name: "transactions",
          desc: "get trasactions in a specified block or for an address (txs for short)",
        },
        {
          name: "transaction",
          desc: "get a transaction for a transaction id (tx for short)",
        },
        {
          name: "confirmation",
          desc: "get a number of confirmations (cf for short)",
        },
        {
          name: "fees",
          desc: "show fees for each action",
        },
      ]
    end

    def option_parser
      create_option_parser([
        Options::CONNECT_NODE,
        Options::WALLET_PATH,
        Options::WALLET_PASSWORD,
        Options::JSON,
        Options::ADDRESS,
        Options::AMOUNT,
        Options::MESSAGE,
        Options::BLOCK_INDEX,
        Options::TRANSACTION_ID,
        Options::FEE,
      ])
    end

    def run_impl(action_name)
      case action_name
      when "send"
        return send
      when "transactions", "txs"
        return transactions
      when "transaction", "tx"
        return transaction
      when "confirmation", "cf"
        return confirmation
      when "fees"
        return fees
      end

      specify_sub_action!(action_name)
    end

    def send
      puts_help(HELP_CONNECTING_NODE) unless node = __connect_node
      puts_help(HELP_WALLET_PATH) unless wallet_path = __wallet_path
      puts_help(HELP_ADDRESS_RECIPIENT) unless recipient_address = __address
      puts_help(HELP_AMOUNT) unless amount = __amount
      puts_help(HELP_FEE) unless fee = __fee

      raise "invalid fee for the action send: minimum fee is #{min_fee_of_action("send")}" if fee < min_fee_of_action("send")

      to_address = Address.from(recipient_address, "recipient")

      wallet = get_wallet(wallet_path, __wallet_password)

      senders = Core::Models::Senders.new
      senders.push(
        {
          address:    wallet.address,
          public_key: wallet.public_key,
          amount:     amount + fee,
        }
      )

      recipients = Core::Models::Recipients.new
      recipients.push(
        {
          address: to_address.as_hex,
          amount:  amount,
        }
      )

      add_transaction(node, wallet, "send", senders, recipients, __message)
    end

    def transactions
      puts_help(HELP_CONNECTING_NODE) unless node = __connect_node
      puts_help(HELP_BLOCK_INDEX_OR_ADDRESS) if __block_index.nil? && __address.nil?

      payload = if block_index = __block_index
                  success_message = "show transactions in a block #{block_index}"
                  {call: "transactions", index: block_index}.to_json
                elsif address = __address
                  success_message = "show transactions for an address #{address}"
                  {call: "transactions", address: address}.to_json
                else
                  puts_help(HELP_BLOCK_INDEX_OR_ADDRESS)
                end

      body = rpc(node, payload)

      puts_success(success_message) unless __json
      puts_info(body)
    end

    def transaction
      puts_help(HELP_CONNECTING_NODE) unless node = __connect_node
      puts_help(HELP_TRANSACTION_ID) unless transaction_id = __transaction_id

      payload = {call: "transaction", transaction_id: transaction_id}.to_json

      body = rpc(node, payload)

      puts_success("show the transaction #{transaction_id}") unless __json
      puts_info(body)
    end

    def confirmation
      puts_help(HELP_CONNECTING_NODE) unless node = __connect_node
      puts_help(HELP_TRANSACTION_ID) unless transaction_id = __transaction_id

      payload = {call: "confirmation", transaction_id: transaction_id}.to_json

      body = rpc(node, payload)

      unless __json
        puts_success("show the number of confirmations of #{transaction_id}")

        json = JSON.parse(body)

        puts_info("transaction id: #{transaction_id}")
        puts_info("--------------")
        puts_info("confirmed: #{json["confirmed"]}")
        puts_info("confirmations: #{json["confirmations"]}")
        puts_info("threshold: #{json["threshold"]}")
      else
        puts_info(body)
      end
    end

    def fees
      unless __json
        puts_success("showing fees for each action.")
        puts_info("send     : #{FEE_SEND}")
      else
        json = {send: FEE_SEND}.to_json
        puts json
      end
    end

    def add_transaction(node : String,
                        wallet : Core::Wallet,
                        action : String,
                        senders : Core::Models::Senders,
                        recipients : Core::Models::Recipients,
                        message : String)
      unsigned_transaction =
        create_unsigned_transaction(node, action, senders, recipients, message)

      signed_transaction = sign(wallet, unsigned_transaction)

      payload = {
        call:        "create_transaction",
        transaction: signed_transaction,
      }.to_json

      rpc(node, payload)

      unless __json
        puts_success "successfully create your transaction!"
        puts_success "=> #{signed_transaction.id}"
      else
        puts signed_transaction.to_json
      end
    end

    def create_unsigned_transaction(node : String,
                                    action : String,
                                    senders : Core::Models::Senders,
                                    recipients : Core::Models::Recipients,
                                    message : String)
      payload = {
        call:       "create_unsigned_transaction",
        action:     action,
        senders:    senders,
        recipients: recipients,
        message:    message,
      }.to_json

      body = rpc(node, payload)

      Core::Transaction.from_json(body)
    end

    def sign(wallet : Core::Wallet, transaction : Core::Transaction) : Core::Transaction
      secp256k1 = Core::ECDSA::Secp256k1.new

      private_key = Wif.new(wallet.wif).private_key

      sign = secp256k1.sign(
        private_key.as_big_i,
        transaction.to_hash,
      )

      transaction.signed(
        sign[0].to_s(base: 16),
        sign[1].to_s(base: 16),
      )
    end

    include Core::Fees
    include GlobalOptionParser
  end
end