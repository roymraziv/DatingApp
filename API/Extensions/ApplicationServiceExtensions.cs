using System;
using API.Data;
using API.Helpers;
using API.Interfaces;
using API.Services;
using API.SignalR;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;

namespace API.Extensions;

public static class ApplicationServiceExtensions
{
    public static IServiceCollection AddApplicationServices(this IServiceCollection services, IConfiguration config)
    {
        services.AddControllers();

        // SQL Server (keep for reference)
        // services.AddDbContext<DataContext>(opt =>
        // {
        //     opt.UseSqlServer(config.GetConnectionString("DefaultConnection"), sqlOptions =>
        //     {
        //         sqlOptions.EnableRetryOnFailure();
        //     });
        // });

        // PostgreSQL (Production)
        services.AddDbContext<DataContext>(opt =>
        {
            opt.UseNpgsql(config.GetConnectionString("DefaultConnection"), npgsql =>
            {
                npgsql.EnableRetryOnFailure();
            });
            // Suppress pending model changes warning at startup so migrations
            // don't throw when the model differs between build-time and runtime.
            opt.ConfigureWarnings(w => w.Ignore(RelationalEventId.PendingModelChangesWarning));
        });
        // Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
        services.AddOpenApi();

        services.AddCors();

        services.AddScoped<ITokenService, TokenService>();
        services.AddScoped<IUserRepository, UserRepository>();
        services.AddScoped<ILikesRepository, LikesRepository>();
        services.AddScoped<IPhotoService, PhotoService>();
        services.AddScoped<IMessageRepository, MessageRepository>();
        services.AddScoped<IUnitOfWork, UnitOfWork>();
        services.AddScoped<LogUserActivity>();
        services.AddScoped<IPhotoRepository, PhotoRepository>();
        services.AddAutoMapper(AppDomain.CurrentDomain.GetAssemblies());
        services.Configure<CloudinarySettings>(config.GetSection("CloudinarySettings"));
        services.AddSignalR();
        services.AddSingleton<PresenceTracker>();
        services.AddHttpContextAccessor();

        return services;
    }
}
