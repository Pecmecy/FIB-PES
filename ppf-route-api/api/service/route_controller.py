from abc import ABC, abstractmethod
from common.models.route import Route, RouteManager


class AbstractRouteController(ABC):
    """
    Defines the interface to be followed by any concrete implementation
    A RouteManager defines the domain operations of the RouteAPI
    """

    @abstractmethod
    def createRoute(serializer) -> Route:
        pass

    @abstractmethod
    def storeRoute(route):
        pass

    @abstractmethod
    def startRoute(routeId) -> bool:
        pass

    @abstractmethod
    def stopRoute(routeId) -> bool:
        pass

    @abstractmethod
    def cancelRoute(routeId) -> bool:
        pass

    @abstractmethod
    def joinPassenger(routeId, passengerId) -> bool:
        pass

    @abstractmethod
    def leavePassenger(routeId, passengerId) -> bool:
        pass


class RouteController(AbstractRouteController):
    routeManager: RouteManager = Route.objects

    # TODO determine if accepting the serializer is the best approach
    def createRoute(self, serializer) -> Route:
        raise NotImplementedError()

    def storeRoute(self, route) -> bool:
        raise NotImplementedError()

    def startRoute(self, routeId) -> bool:
        raise NotImplementedError()

    def stopRoute(self, routeId) -> bool:
        raise NotImplementedError()

    def cancelRoute(self, routeId) -> bool:
        raise NotImplementedError()

    def joinPassenger(self, routeId, passengerId) -> bool:
        raise NotImplementedError()

    def leavePassenger(self, routeId, passengerId) -> bool:
        raise NotImplementedError()
