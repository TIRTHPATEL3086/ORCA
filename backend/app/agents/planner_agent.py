def plan_tools(
    intent: str,
    has_destination: bool,
) -> list[str]:
    if intent == "SEA_CONDITIONS":
        return [
            "Boundary Agent",
            "Ocean & Weather Agent",
        ]

    if intent == "HABITAT":
        return [
            "Boundary Agent",
            "Habitat Intelligence Agent",
        ]

    if intent == "BOUNDARY":
        return [
            "Boundary Agent",
        ]

    if intent == "SAFETY":
        return [
            "Boundary Agent",
            "Ocean & Weather Agent",
            "Risk Agent",
        ]

    if intent == "ROUTE":
        tools = [
            "Boundary Agent",
        ]

        if has_destination:
            tools.extend(
                [
                    "Ocean & Weather Agent",
                    "Route Agent",
                    "Risk Agent",
                ]
            )

        return tools

    if intent == "PFZ":
        return [
            "PFZ Discovery Agent",
            "Boundary Agent",
            "Ocean & Weather Agent",
            "Mission Feasibility Agent",
        ]

    return [
        "Interaction Agent",
    ]
