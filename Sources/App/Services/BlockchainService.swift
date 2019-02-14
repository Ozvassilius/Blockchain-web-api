//
//  BlockchainService.swift
//  App
//
//  Created by Macinstosh on 14/02/2019.
//

import Foundation

class BlockchainService {


    private (set) var blockchain: Blockchain!

    init() {
        self.blockchain = Blockchain(genesisBlock: Block())
    }

    func getBlockchain() -> Blockchain {
        return self.blockchain
    }

    func getNextBlock(transactions: [Transaction]) -> Block {
        let block = self.blockchain.getNextBlock(transactions: transactions)
        self.blockchain.addBlock(block)
        return block
    }

    func registerNodes(nodes: [BlockchainNode]) -> [BlockchainNode] {
        return self.blockchain.registerNodes(nodes: nodes)    
    }

    func getNodes() -> [BlockchainNode] {
        return self.blockchain.nodes
    }

    func resolve(completion: @escaping (Blockchain) -> () ) {

        let nodes = self.blockchain.nodes // on recupere les nodes de la blockchain
        for node in nodes {
            let url = URL(string: "\(node.address)/blockchain")! // on conctruit l'url
            URLSession.shared.dataTask(with: url) { (data, _, _) in
                if let data = data {
                    // on decode les blockchains pour les comparer
                    let blockchain = try! JSONDecoder().decode(Blockchain.self, from: data)

                    // on trouve ici la blockchain la plus long
                    if self.blockchain.blocks.count > blockchain.blocks.count {
                        completion(self.blockchain)
                    } else {
                         self.blockchain = blockchain
                        completion(blockchain)
                    }
                }
            }.resume()
        }
    }

}
