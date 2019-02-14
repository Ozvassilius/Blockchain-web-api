import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {

    // on reference notre BlockchainController
    let blockchainController = BlockchainController()
    router.get("hello", use: blockchainController.greet)

    // retourne la blockchain
    router.get("blockchain", use: blockchainController.getBlockchain)

    // Mine
    router.post(Transaction.self, at: "mine", use: blockchainController.mine)

    // enregistrer un node
    router.post([BlockchainNode].self, at: "/nodes/register", use: blockchainController.registerNodes)

    // recuperer un node
    router.get("/nodes", use: blockchainController.getNodes)

    // resoudre conflit de longueur de chaine
    router.get("/resolve", use: blockchainController.resolve)

}
