def serializeLicitacio(charger):
    data = {
        "latitud": charger.latitud,
        "longitud": charger.longitud,
        "nomOrgan": charger.promotorGestor,
        "tipus": "Servei",
        "procediment": "Obert",
        "fasePublicacio": "Formalització",
        "denominacio": "Servei de recàrrega de vehicles elèctrics espatllat",
        "llocExecucio": charger.adreA,
        "nomAmbit": "PowerPathFinder",
        "pressupost": 3.69,
    }
    return data
