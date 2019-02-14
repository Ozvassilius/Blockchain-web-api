//
//  Models.swift
//  App
//
//  Created by Macinstosh on 14/02/2019.
//

import Cocoa
import Vapor

final class BlockchainNode: Content {

    var address: String

    init(address: String) {
        self.address =  address
    }

}

protocol SmartContract {
    func apply(transaction: Transaction)

}

final class TransactionTypeSmartContract : SmartContract {

    // application des frais selon le type de transaction
    func apply(transaction: Transaction) {
        var fees = 0.0

        switch transaction.transactionType {
        case .domestic:
            fees = 0.02
        case .international:
            fees = 0.05
        }



        transaction.fees = transaction.amount * fees // calcul des frais
        transaction.amount -= transaction.fees // le montant de la transactin diminué des frais

    }
}

enum TransactionType : String, Content {
    case domestic
    case international
}

final class Transaction : Content { // Codable: swift feature pour serialiser en json object
    // va nous permettre de serialiser notre liste de transaction
    // afin d'en faire une string dans la class Block nécessaire pour genérer la key
    var from: String
    var to: String
    var amount: Double
    var fees: Double = 0.0
    var transactionType: TransactionType

    init(from: String, to:String, amount: Double, transactionType: TransactionType) {
        self.from = from
        self.to = to
        self.amount = amount
        self.transactionType = transactionType
    }
}

final class Block : Content {

    var index: Int = 0 // l'index du block dans la blockchain, si c'est le premier block il vaut 0 / position du block dans la blockchain
    var previousHash: String = "" // le block 1 est construit avec la transaction  + nonce + previousHash
    var hash: String! // hash du block actuel
    // le hash va etre initialisé/créé quand on fera le proof of work algorithm
    var nonce: Int

    private (set) var transactions: [Transaction] = [Transaction]() // a block contient en effet un set(une liste) de transactions

    // il faut generer la key utilisé pour generer le hash
    // key = index + hash of previous transaction + nonce + transaction
    var key: String {
        get {
            let transactionsData = try! JSONEncoder().encode(self.transactions)
            let transactionsJSONString = String(data: transactionsData, encoding: .utf8)
            return String(self.index) + self.previousHash + String(self.nonce) + transactionsJSONString!
        }
    }

    func addTransaction(transaction: Transaction) {
        self.transactions.append(transaction)
    }



    init() {
        self.nonce = 0
    }
}

// A Savoir: du moment que je defini une class Codable
// tous les objets et class a l'interieur doivent etre Codable
final class Blockchain : Content {

    private (set) var blocks = [Block]()
    private (set) var nodes = [BlockchainNode]()

    // liste de smartContracts, on peut avoir plusieurs smartcontracts
    // Attention SmartContract n'etant pas Codable alors que Blockchain oui
    // nous devons utilisé une feature de Swift 4
    // l'enum avec CodingKey specifie que seul le cas block sera utilisé en Codable
    private (set) var smartContracts: [SmartContract] = [TransactionTypeSmartContract()]

    // intialisation de la blockchain
    init(genesisBlock: Block) {
        addBlock(genesisBlock) // ajout du genesisBlock
    }

    func registerNodes(nodes: [BlockchainNode]) -> [BlockchainNode] {
        self.nodes.append(contentsOf: nodes)
        return  self.nodes
    }

    private enum CodingKeys: CodingKey {
        case blocks
    }


    func addBlock(_ block: Block)  {

        if self.blocks.isEmpty { // on verifie si on est au genesisBlock
            block.previousHash = "0000000000000000"
            block.hash = generateHash(for: block)
        }

        // run the smart contracts
        self.smartContracts.forEach { contract in
            block.transactions.forEach { transaction in
                contract.apply(transaction: transaction)
            }
        }

        self.blocks.append(block)
    }

    func getNextBlock(transactions: [Transaction]) -> Block {

        let block = Block() // placeholder
        transactions.forEach { transaction in
            block.addTransaction(transaction: transaction)
        }

        let previousBlock = getPreviousBlock()
        block.index = self.blocks.count
        block.previousHash = previousBlock.hash
        block.hash = generateHash(for: block)
        return block

    }

    private func getPreviousBlock() -> Block {
        return self.blocks[self.blocks.count - 1]
    }

    func generateHash(for block: Block) -> String {

        var hash = block.key.sha1Hash()
        // le cryptage n'est pas assez secure, n'importe qui peut utilisé la meme fonction
        // on va donc rajouter une condition
        // faire un hash qui commence par 00
        // cela prend mnt une 15aines de seconde

        while (!hash.hasPrefix("00")) {
            block.nonce += 1
            hash = block.key.sha1Hash()
            print(hash)
        }

        return hash
    }

}

// String Extension
extension String {

    // utilise des fonctions basique de macOs pour generer le hash
    func sha1Hash() -> String {

        let task = Process()
        task.launchPath = "/usr/bin/shasum"
        task.arguments = []

        let inputPipe = Pipe()

        inputPipe.fileHandleForWriting.write(self.data(using: String.Encoding.utf8)!)

        inputPipe.fileHandleForWriting.closeFile()

        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardInput = inputPipe
        task.launch()

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let hash = String(data: data, encoding: String.Encoding.utf8)!
        return hash.replacingOccurrences(of: "  -\n", with: "")
    }
}


