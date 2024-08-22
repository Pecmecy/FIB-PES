import time
from typing import Tuple

import numpy as np
from geopy.distance import distance
from sklearn.neighbors import NearestNeighbors

origin = (41.11364, 1.22503)
waypoints = {
    "69": (41.38553, 2.19359),
    "92": (41.39245, 2.12909),
    "93": (41.42596, 2.18416),
    "110": (41.374657, 2.160033),
    "115": (41.429405, 2.158544),
    "147": (41.39661, 2.200294),
    "165": (41.388134, 2.107238),
    "183": (41.446396, 1.973947),
    "221": (41.42767, 2.17721),
    "233": (41.390976, 2.196397),
    "235": (41.482746, 2.051307),
    "289": (41.43698, 2.191159),
    "306": (41.392723, 2.146466),
    "307": (41.395523, 2.153667),
    "330": (41.40716, 2.138525),
    "336": (41.40681, 2.133584),
    "353": (41.394066, 2.108034),
    "361": (41.38495, 2.11611),
    "366": (41.401306, 2.13352),
    "376": (41.37711, 2.119567),
    "380": (41.397346, 2.119925),
    "393": (41.405376, 2.143079),
    "444": (41.4424, 2.197355),
    "445": (41.35291, 2.088723),
    "466": (41.38216, 2.184037),
    "484": (41.454933, 2.226736),
    "505": (41.40297, 2.189897),
    "506": (41.40837, 2.202957),
    "511": (41.419018, 2.178893),
    "570": (41.41357, 2.143069),
    "579": (41.38109, 2.142061),
    "580": (41.389957, 2.128359),
    "584": (41.405376, 2.149945),
    "587": (41.3945, 2.152312),
    "589": (41.40177, 2.150899),
    "648": (41.403248, 2.152312),
    "688": (41.3828, 2.19435),
    "706": (41.41613, 2.18056),
    "708": (41.38687, 2.19763),
    "761": (41.44475, 2.174366),
    "769": (41.37216, 2.15668),
    "793": (41.44219, 2.1777),
    "797": (41.406513, 2.200808),
    "821": (41.39792, 2.1255),
    "828": (41.381737, 2.17007),
    "833": (41.387524, 2.131688),
    "861": (41.4098, 2.154),
    "896": (41.42006, 2.201705),
    "914": (41.40476, 2.18961),
    "915": (41.434628, 2.148196),
    "943": (41.42686, 2.14359),
    "944": (41.510914, 2.133097),
    "963": (41.44156, 2.200143),
    "979": (41.419113, 2.001132),
    "1007": (41.353497, 2.122741),
    "1034": (41.394184, 2.123801),
    "1062": (41.37951, 2.162065),
    "1102": (41.39388, 2.18155),
    "1107": (41.29726, 2.008494),
    "1110": (41.39991, 2.12341),
    "1119": (41.40512, 2.20753),
    "1124": (41.400993, 2.185633),
    "1128": (41.4022, 2.2046),
    "1130": (41.446304, 1.974044),
    "1139": (41.39384, 2.156069),
    "1146": (41.39441, 2.114755),
    "1147": (41.393227, 2.145783),
    "1163": (41.44926, 2.190651),
    "1171": (41.40585, 2.16264),
    "1191": (41.40572, 2.19278),
    "1218": (41.409256, 2.168206),
    "1263": (41.384617, 2.122279),
    "1267": (41.398552, 2.186638),
    "1269": (41.375282, 2.130336),
    "1277": (41.372803, 2.154058),
    "1280": (41.4045, 2.1972),
    "1305": (41.359947, 2.133299),
    "1320": (41.38208, 2.191611),
    "1322": (41.31811, 2.07489),
    "1334": (41.43052, 2.18798),
    "1371": (41.42367, 2.179258),
    "1393": (41.411564, 2.218659),
    "1397": (41.394295, 2.169688),
    "1407": (41.396866, 2.170576),
    "1425": (41.459743, 2.175609),
    "1428": (41.41993, 2.181425),
    "1445": (41.37592, 2.188999),
    "1470": (41.37445, 2.072167),
    "1481": (41.49244, 2.185111),
    "1521": (41.40645, 2.15223),
    "1566": (41.3962, 2.158994),
    "1639": (41.1211, 1.2720202),
    "1724": (41.405136, 2.177452),
    "1725": (41.392338, 2.132172),
    "1738": (41.37643, 2.178412),
    "1747": (41.40683, 2.21849),
    "1756": (41.413143, 2.221153),
    "1758": (41.38028, 2.18729),
    "1765": (41.387108, 2.17143),
    "1786": (41.389233, 2.161352),
}
destination = (42.18049, 2.48195)
points = {
    "origin": origin,
    "destination": destination,
    **waypoints,
}


def toPointMatrix(points: dict[str, tuple[float, float]]):
    return np.array(list(points.values()))


def vectDistance(point1: list[float], point2: list[float]):
    return distance(list(point1), list(point2)).km


def kPowerFinder(
    autonomy: float,
    points: dict[str, tuple[float, float]],
    deviationParam: float = 0.1,
    reductionParam: float = 0.05,
    slim: bool = False,
) -> list[Tuple[float, float]]:
    """
    Reduces the number of candidate points to find the best path to the destination.

    It does so searching points on the ring of radius 'autonomy' and 'autonomy*(1-reductionParam)'.
    Reduces the inner radius until one or more points are found, this are meant to be the furthest
    points from the origin. Then sets the origin to the nearest point to the destination and repeats
    the process until the destination is reached.

    Args:
        autonomy (float): The autonomy of the vehicle.
        points (dict[str, tuple[float, float]]): A dictionary of points, where the keys are the
            names of the points and the values are tuples representing the coordinates of the
            points. Must contain the keys 'origin' and 'destination'.
        deviationParam (float, optional): The deviation parameter. Defaults to 0.1.
            deviationParam is intended to compensate for the road deviation of the path from the
            straight line between points.
        reductionParam (float, optional): The reduction parameter. Defaults to 0.05.
            reductionParam is the reduction of the autonomy in each iteration. In other words,
            how much the search zone increases in each iteration.
        slim (bool, optional): Whether to use the slim mode or not. Defaults to False.
            slim mode only adds the nearest point to the destination as a candidate.
            This reduces the number of candidates and speeds up the process but reduces
            the number of possible paths and hence the chance of finding the best path.

    Returns:
        List of Tuple[np.ndarray[Any, Any], csr_matrix]: A list of tuples containing the candidate points.

    Raises:
        RuntimeError: If the destination is unreachable.

    Notes:
        - This algorithm assumes that the destination is NOT reachable from the origin, so it should be checked
          before calling this function.
    """
    # Since we deal with straight lines we reduce the autonomy
    autonomy = autonomy * (1 - deviationParam)
    pointMatrix = np.array(list(points.values()))  # get the points as a matrix
    origin = points["origin"]
    destination = points["destination"]
    if origin is None or destination is None:
        raise ValueError(
            "'points' does not contain 'origin' or 'destination' keys")
    candidatePoints: np.ndarray = np.ndarray((1, 2), buffer=np.array([origin]))

    while destination not in candidatePoints:
        # Search neighbors that are reachable from a reduced autonomy
        knn = NearestNeighbors(
            radius=autonomy, metric=vectDistance).fit(pointMatrix)
        reachable = knn.radius_neighbors_graph(
            [np.array(list(origin))], radius=autonomy, mode="distance", sort_results=True
        )

        autonomy2 = autonomy * (1 - reductionParam)
        while autonomy2 > 0.0:
            reachablePrime = knn.radius_neighbors_graph(
                [np.array(list(origin))], radius=autonomy2, mode="distance", sort_results=True
            )
            # get the points from ¬R ∩ R' [¬(reachable) ∩ (reachablePrime)]
            # basically the points further than 'autonomy2' but lower than 'autonomy'
            result = np.setdiff1d(
                reachable.indices, np.intersect1d(
                    reachable.indices, reachablePrime.indices), True
            )
            if len(result) > 0:
                # when we one or more points that satisfy the set operation get the nearest point
                # from candidatePoints to the destination
                # (the furthest point from the origin might not be the best candidate)
                newCandidates = pointMatrix[result]
                for candidate in newCandidates:
                    if distance(candidate, destination).km < distance(origin, destination).km:
                        origin = candidate

                if slim:
                    # if slim is set we add only the nearest point to the destination as a candidate
                    candidatePoints = np.append(
                        candidatePoints, [origin], axis=0)
                else:
                    # if slim is not set we add all the points that satisfy the set operation
                    candidatePoints = np.append(
                        candidatePoints, pointMatrix[result], axis=0)

                # we get rid of the initially reachable points as we don't want to consider them
                # again. This allows us to progress towards the destination
                pointMatrix = np.delete(pointMatrix, reachable.indices, axis=0)

                # if the destination is the only point left we add it to the candidatePoints
                # if not the destination is unreachable
                if len(pointMatrix) == 1:
                    if pointMatrix[0].tolist() == list(destination):
                        candidatePoints = np.append(
                            candidatePoints, pointMatrix, axis=0)
                    else:
                        raise ValueError("Destination is unreachable")
                break
            autonomy2 -= autonomy * reductionParam
            # if autonomy2 hits 0 we can consider that the destination is unreachable
            # TODO there might be safer break conditions
            if autonomy2 <= 0:
                raise ValueError("Destination is unreachable")
    # convert from np.ndarray to list of tuples and do not include the origin and destination
    tupleList = []
    for coord in candidatePoints.tolist():
        coord = tuple(coord)
        if coord != points["origin"] and coord != points["destination"]:
            tupleList.append(tuple(coord))
    return tupleList


def prepareForDijkstra(returnedCandidates, graph):
    """
    Prepares the data to be used in the dijkstra function.

    Args:
        returnedCandidates (list): A list of candidate points.
        graph (csr_matrix): The distance graph between the candidate points.

    Returns:
        dict: A dictionary with the candidate points and the graph in the format expected by the dijkstra function.
    """
    dijkstraGraph = {}
    for i, point in enumerate(returnedCandidates):
        dijkstraGraph[str(i)] = {}
        for j, distance in enumerate(graph[i].toarray()[0]):
            if distance > 0:
                dijkstraGraph[str(i)][str(j)] = distance
    return dijkstraGraph


if __name__ == "__main__":
    from dijkstra import dijkstra
    """
    When executing this file kPowerFinder executes with different combinations of arguments and
    measures the execution time. It prints the results in a tabular format.
    """
    # Define different argument combinations
    autonomy_values = [80, 90, 100, 120]
    deviation_values = [0.05, 0.10, 0.15, 0.20]
    reduction_values = [0.05, 0.10, 0.15, 0.20]
    slim_values = [True, False]

    # Execute kPowerFinder function 5 times for each argument combination
    print("Autonomy\tDeviation\tReduction\tslim\tTIME (s)")
    print("-" * 64)
    for slim in slim_values:
        for reduction in reduction_values:
            for deviation in deviation_values:
                for autonomy in autonomy_values:
                    times = []
                    broke = False
                    for _ in range(5):
                        start_time = time.time()
                        try:
                            returnedCandidates, graph = kPowerFinder(autonomy, points,
                                                                     deviation, reduction, slim)
                            dijkstraGraph = prepareForDijkstra(
                                returnedCandidates, graph)
                            finalPath = dijkstra(
                                dijkstraGraph, "0", str(len(returnedCandidates) - 1), autonomy)
                        except ValueError as e:
                            print(f"Falied for {autonomy}, {
                                  deviation}, {reduction}, {slim}")
                            broke = True
                            break
                        end_time = time.time()
                        execution_time = end_time - start_time
                        times.append(execution_time)
                    if broke:
                        continue
                    # Remove the max and min values
                    times.remove(max(times))
                    times.remove(min(times))
                    # Calculate the average execution time
                    average_time = round(sum(times) / len(times), 4)
                    print(f"{autonomy}\t\t{deviation}\t\t{
                          reduction}\t\t{slim}\t{average_time}")
