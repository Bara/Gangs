bool IsValidDatabase(Database db, const char[] error)
{
    if (db == null || strlen(error))
    {
        return false;
    }

    return true;
}
