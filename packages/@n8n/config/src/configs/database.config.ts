import { z } from 'zod';

import { Config, Env, Nested } from '../decorators';

const dbLoggingOptionsSchema = z.enum(['query', 'error', 'schema', 'warn', 'info', 'log', 'all']);
type DbLoggingOptions = z.infer<typeof dbLoggingOptionsSchema>;

@Config
class LoggingConfig {
	/**
	 * 是否启用数据库日志。
	 * @Env DB_LOGGING_ENABLED
	 */
	@Env('DB_LOGGING_ENABLED')
	enabled: boolean = false;

	/**
	 * 数据库日志级别。需要 `DB_LOGGING_MAX_EXECUTION_TIME` 大于 0。
	 * @Env DB_LOGGING_OPTIONS
	 */
	@Env('DB_LOGGING_OPTIONS', dbLoggingOptionsSchema)
	options: DbLoggingOptions = 'error';

	/**
	 * 只有超过此时间（毫秒）的查询才会被记录。设置为 0 以禁用。
	 * @Env DB_LOGGING_MAX_EXECUTION_TIME
	 */
	@Env('DB_LOGGING_MAX_EXECUTION_TIME')
	maxQueryExecutionTime: number = 0;
}

@Config
class PostgresSSLConfig {
	/**
	 * 是否启用 SSL。
	 * 如果定义了 `DB_POSTGRESDB_SSL_CA`、`DB_POSTGRESDB_SSL_CERT` 或 `DB_POSTGRESDB_SSL_KEY`，则 `DB_POSTGRESDB_SSL_ENABLED` 默认为 `true`。
	 * @Env DB_POSTGRESDB_SSL_ENABLED
	 */
	@Env('DB_POSTGRESDB_SSL_ENABLED')
	enabled: boolean = false;

	/**
	 * SSL 证书颁发机构。
	 * @Env DB_POSTGRESDB_SSL_CA
	 */
	@Env('DB_POSTGRESDB_SSL_CA')
	ca: string = '';

	/**
	 * SSL 证书。
	 * @Env DB_POSTGRESDB_SSL_CERT
	 */
	@Env('DB_POSTGRESDB_SSL_CERT')
	cert: string = '';

	/**
	 * SSL 密钥。
	 * @Env DB_POSTGRESDB_SSL_KEY
	 */
	@Env('DB_POSTGRESDB_SSL_KEY')
	key: string = '';

	/**
	 * 是否应拒绝未经授权的 SSL 连接。
	 * @Env DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED
	 */
	@Env('DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED')
	rejectUnauthorized: boolean = true;
}

@Config
class PostgresConfig {
	/**
	 * Postgres 数据库名称。
	 * @Env DB_POSTGRESDB_DATABASE
	 */
	@Env('DB_POSTGRESDB_DATABASE')
	database: string = 'n8n';

	/**
	 * Postgres 数据库主机。
	 * @Env DB_POSTGRESDB_HOST
	 */
	@Env('DB_POSTGRESDB_HOST')
	host: string = 'localhost';

	/**
	 * Postgres 数据库密码。
	 * @Env DB_POSTGRESDB_PASSWORD
	 */
	@Env('DB_POSTGRESDB_PASSWORD')
	password: string = '';

	/**
	 * Postgres 数据库端口。
	 * @Env DB_POSTGRESDB_PORT
	 */
	@Env('DB_POSTGRESDB_PORT')
	port: number = 5432;

	/**
	 * Postgres 数据库用户。
	 * @Env DB_POSTGRESDB_USER
	 */
	@Env('DB_POSTGRESDB_USER')
	user: string = 'postgres';

	/**
	 * Postgres 数据库模式。
	 * @Env DB_POSTGRESDB_SCHEMA
	 */
	@Env('DB_POSTGRESDB_SCHEMA')
	schema: string = 'public';

	/**
	 * Postgres 数据库连接池大小。
	 * @Env DB_POSTGRESDB_POOL_SIZE
	 */
	@Env('DB_POSTGRESDB_POOL_SIZE')
	poolSize: number = 2;

	/**
	 * Postgres 连接超时时间（毫秒）。
	 * @Env DB_POSTGRESDB_CONNECTION_TIMEOUT
	 */
	@Env('DB_POSTGRESDB_CONNECTION_TIMEOUT')
	connectionTimeoutMs: number = 20_000;

	/**
	 * Postgres 空闲连接超时时间（毫秒）。
	 * @Env DB_POSTGRESDB_IDLE_CONNECTION_TIMEOUT
	 */
	@Env('DB_POSTGRESDB_IDLE_CONNECTION_TIMEOUT')
	idleTimeoutMs: number = 30_000;

	@Nested
	ssl: PostgresSSLConfig;
}

@Config
class MysqlConfig {
	/**
	 * @deprecated MySQL 数据库名称。
	 * @Env DB_MYSQLDB_DATABASE
	 */
	@Env('DB_MYSQLDB_DATABASE')
	database: string = 'n8n';

	/**
	 * MySQL 数据库主机。
	 * @Env DB_MYSQLDB_HOST
	 */
	@Env('DB_MYSQLDB_HOST')
	host: string = 'localhost';

	/**
	 * MySQL 数据库密码。
	 * @Env DB_MYSQLDB_PASSWORD
	 */
	@Env('DB_MYSQLDB_PASSWORD')
	password: string = '';

	/**
	 * MySQL 数据库端口。
	 * @Env DB_MYSQLDB_PORT
	 */
	@Env('DB_MYSQLDB_PORT')
	port: number = 3306;

	/**
	 * MySQL 数据库用户。
	 * @Env DB_MYSQLDB_USER
	 */
	@Env('DB_MYSQLDB_USER')
	user: string = 'root';
}

@Config
export class SqliteConfig {
	/**
	 * SQLite 数据库文件名。
	 * @Env DB_SQLITE_DATABASE
	 */
	@Env('DB_SQLITE_DATABASE')
	database: string = 'database.sqlite';

	/**
	 * SQLite 数据库连接池大小。设置为 0 以禁用池化。
	 * @Env DB_SQLITE_POOL_SIZE
	 */
	@Env('DB_SQLITE_POOL_SIZE')
	poolSize: number = 0;

	/**
	 * 启用 SQLite WAL 模式。
	 * @Env DB_SQLITE_ENABLE_WAL
	 */
	@Env('DB_SQLITE_ENABLE_WAL')
	enableWAL: boolean = this.poolSize > 1;

	/**
	 * 在启动时运行 `VACUUM` 以重建数据库，减小文件大小并优化索引。
	 *
	 * @warning 这是一个长时间运行的阻塞操作，会增加启动时间。
	 * @Env DB_SQLITE_VACUUM_ON_STARTUP
	 */
	@Env('DB_SQLITE_VACUUM_ON_STARTUP')
	executeVacuumOnStartup: boolean = false;
}

const dbTypeSchema = z.enum(['sqlite', 'mariadb', 'mysqldb', 'postgresdb']);
type DbType = z.infer<typeof dbTypeSchema>;

@Config
export class DatabaseConfig {
	/**
	 * 要使用的数据库类型。
	 * @Env DB_TYPE
	 */
	@Env('DB_TYPE', dbTypeSchema)
	type: DbType = 'sqlite';

	/**
	 * 如果使用的是 TypeORM 的默认 sqlite 数据源，则为 true，
	 * 而不是任何其他数据源（例如 postgres）。
	 * 如果使用的是 n8n 新的池化 sqlite 数据源，此项也返回 false。
	 */
	get isLegacySqlite() {
		return this.type === 'sqlite' && this.sqlite.poolSize === 0;
	}

	/**
	 * 表名前缀。
	 * @Env DB_TABLE_PREFIX
	 */
	@Env('DB_TABLE_PREFIX')
	tablePrefix: string = '';

	/**
	 * ping 数据库以检查连接是否仍然存活的间隔（秒）。
	 * @Env DB_PING_INTERVAL_SECONDS
	 */
	@Env('DB_PING_INTERVAL_SECONDS')
	pingIntervalSeconds: number = 2;

	@Nested
	logging: LoggingConfig;

	@Nested
	postgresdb: PostgresConfig;

	@Nested
	mysqldb: MysqlConfig;

	@Nested
	sqlite: SqliteConfig;
}
