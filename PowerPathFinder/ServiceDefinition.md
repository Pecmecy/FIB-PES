## System Operations

This step’s deliverables consist of the following:

For each system operation:
- System operation specification canvas - describes a system operation’s
    - signature - parameters and return value types
    - behavior - the aggregates that are read and written
    - non-functional requirements - e.g. responsive time, latency, throughput, …
- Sequence diagram(s)
- Domain model - Describing the aggregates that the system operations read and write. The next step of the Assemblage process refines this model into subdomains.

**Create User**
_signature:_ User createUser(name, mail, pass)
_behavior:_ User

**Modify User**  
_signature_ User modifyUser(userId, name, mail, pass, authToken)
_behavior:_ User

**LogIn User**
_signature_ authToken logIn(mail, pass)
_behavior:_ User

**Create Route**
_signature_ Route createRoute(userId, origin, destination, departureTime, authToken)
_behavior:_ Route, User

**Modify Route**
_signature_ Route modifyRoute(origin, destination, departureTime, authToken)
_behavior:_ Route

**Join Route**
_signature_ bool joinRoute(userId, routeId, authToken)
_behavior:_ Route, User

**Leave Route**
_signature_ bool leaveRoute(userId, routeId, authToken)
_behavior:_ Route, User
