from drf_yasg.openapi import IN_QUERY, TYPE_ARRAY, Parameter

listIncludeFilter = Parameter(
    "include",
    IN_QUERY,
    description="Specify if cancelled and finalized routes should be included.\nPossible values:'cancelled','finalized'",
    items=["cancelled", "finalized"],  # this does not work
    type=TYPE_ARRAY,
)
