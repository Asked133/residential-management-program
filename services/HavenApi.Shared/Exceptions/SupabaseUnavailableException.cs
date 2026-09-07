namespace HavenApi.Shared.Exceptions;

public class SupabaseUnavailableException : SupabaseDomainException
{
    public SupabaseUnavailableException(string message) : base(message)
    {
    }

    public SupabaseUnavailableException(string message, Exception innerException) : base(message, innerException)
    {
    }
}
