//
//  BlockchainController.swift
//  App
//
//  Created by Macinstosh on 14/02/2019.
//

import Foundation
import Vapor

class BlockchainController {

    private (set) var blockchainService: BlockchainService

    init() {
        self.blockchainService = BlockchainService()
    }

    // fonction d'acceuil pour verifier que cela fonctionne
    // on veut retourner une String mais on utilise Future<String>
    // qui vient de Vapor et signifie que la fonction ne sera pas bloquante
    // et que le resultat sera retourné quand il sera pret
    func greet(req: Request) -> Future<String> {

        // comment renvoyer un future
        return Future.map(on: req) { () -> String in
            return "Welcome to Blockchain"
        }
    }

    // si notre BlockchainService avait utilisé des async nous aurions du renvoyer Future<Blockchain>
    // mais cela n'est pas necessaire dans notre cas
    func getBlockchain(req: Request) -> Blockchain {
        return self.blockchainService.getBlockchain()
    }

    // minage
    func mine(req: Request, transaction: Transaction) -> Block {
        return self.blockchainService.getNextBlock(transactions: [transaction])
    }

    func registerNodes(req: Request, nodes: [BlockchainNode]) -> [BlockchainNode] {
        return self.blockchainService.registerNodes(nodes: nodes)
    }

    func getNodes(req: Request) -> [BlockchainNode] {
        return self.blockchainService.getNodes()
    }

    // notre resolution fait appel a une URLSession
    // nous devons donc attendre un temps de data
    // on renvoi donc un Future et on utilise l'eventLoopPromise
    func resolve(req: Request) -> Future<Blockchain> {
        let promise: EventLoopPromise<Blockchain> = req.eventLoop.newPromise()
        blockchainService.resolve {
            promise.succeed(result: $0)
        }
        return promise.futureResult
    }
}
