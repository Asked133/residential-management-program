namespace HavenApi.Shared.Exceptions;

public class SupabaseDomainException : Exception
{
    public SupabaseDomainException(string message) : base(message)
    {
    }

    public SupabaseDomainException(string message, Exception innerException) : base(message, innerException)
    {
    }
}
