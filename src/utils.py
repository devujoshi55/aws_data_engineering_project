import sys
from datetime import datetime
from awsglue.utils import getResolvedOptions

def get_option(parameter: str):
    """
    Fetch a Glue job parameter.
    If parameter is 'valuation', return a datetime.date object.
    Otherwise, return string.
    """

    args = getResolvedOptions(sys.argv, [parameter])
    value = args[parameter]

    if parameter == "valuation":
        # Expected format: YYYY-MM-DD
        return datetime.strptime(value, "%Y-%m-%d").date()

    return value
