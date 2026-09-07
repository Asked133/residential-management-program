namespace HavenApi.Shared.Exceptions;

public class SupabaseResponseException : SupabaseDomainException
{
    public SupabaseResponseException(string message) : base(message)
    {
    }

    public SupabaseResponseException(string message, Exception innerException) : base(message, innerException)
    {
    }
}
