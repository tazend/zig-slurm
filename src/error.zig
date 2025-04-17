const c = @import("c.zig").c;
const std = @import("std");

// This always returns a valid string.
pub extern fn slurm_strerror(errnum: c_int) [*:0]const u8;

pub const ErrorBundle = struct {
    code: Error,
    description: [:0]const u8,
};

pub fn getErrorBundle() ?ErrorBundle {
    const errno = std.c._errno().*;

    checkRpc(errno) catch |error_code| {
        const errstr = slurm_strerror(errno);
        return ErrorBundle{
            .code = error_code,
            .description = std.mem.span(errstr),
        };
    };
    return null;
}

pub fn getError() Error!void {
    return checkRpc(std.c._errno().*);
}

pub fn getErrorString() ?[:0]const u8 {
    const errno = std.c._errno().*;
    const errstr = slurm_strerror(errno);
    return std.mem.span(errstr);
}

pub const Error = error{
    Generic,
    UnexpectedMsg,
    CommunicationsConnection,
    CommunicationsSend,
    CommunicationsReceive,
    CommunicationsShutdown,
    ProtocolVersion,
    ProtocolIoStreamVersion,
    ProtocolAuthentication,
    ProtocolInsaneMsgLength,
    MpiPluginNameInvalid,
    MpiPluginPrelaunchSetupFailed,
    PluginNameInvalid,
    UnknownForwardAddr,
    CommunicationsMissingSocket,
    SlurmctldCommunicationsConnection,
    SlurmctldCommunicationsSend,
    SlurmctldCommunicationsReceive,
    SlurmctldCommunicationsShutdown,
    SlurmctldCommunicationsBackoff,
    NoChangeInData,
    InvalidPartitionName,
    DefaultPartitionNotSet,
    AccessDenied,
    JobMissingRequiredPartitionGroup,
    RequestedNodesNotInPartition,
    TooManyRequestedCpus,
    InvalidNodeCount,
    OnDescToRecordCopy,
    JobMissingSizeSpecification,
    JobScriptMissing,
    UserIdMissing,
    DuplicateJobId,
    PathnameTooLong,
    NotTopPriority,
    RequestedNodeConfigUnavailable,
    RequestedPartConfigUnavailable,
    NodesBusy,
    InvalidJobId,
    InvalidNodeName,
    WritingToFile,
    TransitionStateNoUpdate,
    AlreadyDone,
    InterconnectFailure,
    BadDist,
    JobPending,
    BadTaskCount,
    InvalidJobCredential,
    InStandbyMode,
    InvalidNodeState,
    InvalidFeature,
    InvalidAuthtypeChange,
    ActiveFeatureNotSubset,
    InvalidSchedtypeChange,
    InvalidSelecttypeChange,
    InvalidSwitchtypeChange,
    Fragmentation,
    NotSupported,
    Disabled,
    Dependency,
    BatchOnly,
    LicensesUnavailable,
    TakeoverNoHeartbeat,
    JobHeld,
    InvalidCredTypeChange,
    InvalidTaskMemory,
    InvalidAccount,
    InvalidParentAccount,
    SameParentAccount,
    InvalidLicenses,
    NeedRestart,
    AccountingPolicy,
    InvalidTimeLimit,
    ReservationAccess,
    ReservationInvalid,
    InvalidTimeValue,
    ReservationBusy,
    ReservationNotUsable,
    InvalidWckey,
    ReservationOverlap,
    PortsBusy,
    PortsInvalid,
    PrologRunning,
    NoSteps,
    MissingWorkDir,
    InvalidQos,
    QosPreemptionLoop,
    NodeNotAvail,
    InvalidCpuCount,
    PartitionNotAvail,
    CircularDependency,
    InvalidGres,
    JobNotPending,
    QosThres,
    PartitionInUse,
    StepLimit,
    JobSuspended,
    CanNotStartImmediately,
    InterconnectBusy,
    ReservationEmpty,
    InvalidArray,
    ReservationNameDup,
    JobStarted,
    JobFinished,
    JobNotRunning,
    JobNotPendingNorRunning,
    JobNotSuspended,
    JobNotFinished,
    TriggerDup,
    Internal,
    InvalidBurstBufferChange,
    BurstBufferPermission,
    BurstBufferLimit,
    InvalidBurstBufferRequest,
    PrioResetFail,
    CannotModifyCronJob,
    InvalidJobContainerChange,
    CannotCancelCronJob,
    InvalidMcsLabel,
    BurstBufferWait,
    PartitionDown,
    DuplicateGres,
    JobSettingDbInx,
    RsvAlreadyStarted,
    SubmissionsDisabled,
    NotHetJob,
    NotHetJobLeader,
    NotWholeHetJob,
    CoreReservationUpdate,
    DuplicateStepId,
    InvalidCoreCnt,
    X11NotAvail,
    GroupIdMissing,
    BatchConstraint,
    InvalidTres,
    InvalidTresBillingWeights,
    InvalidJobDefaults,
    ReservationMaint,
    InvalidGresType,
    RebootInProgress,
    MultiKnlConstraint,
    UnsupportedGres,
    InvalidNice,
    InvalidTimeMinLimit,
    Defer,
    ConfiglessDisabled,
    EnvironmentMissing,
    ReservationNoSkip,
    ReservationUserGroup,
    PartitionAssoc,
    InStandbyUseBackup,
    BadThreadPerCore,
    InvalidPrefer,
    InsufficientGres,
    InvalidContainerId,
    EmptyJobId,
    InvalidJobIdZero,
    InvalidJobIdNegative,
    InvalidJobIdTooLarge,
    InvalidJobIdNonNumeric,
    EmptyJobArrayId,
    InvalidJobArrayIdNegative,
    InvalidJobArrayIdTooLarge,
    InvalidJobArrayIdNonNumeric,
    InvalidHetJobAndArray,
    EmptyHetJobComp,
    InvalidHetJobCompNegative,
    InvalidHetJobCompTooLarge,
    InvalidHetJobCompNonNumeric,
    EmptyStepId,
    InvalidStepIdNegative,
    InvalidStepIdTooLarge,
    InvalidStepIdNonNumeric,
    EmptyHetStep,
    InvalidHetStepZero,
    InvalidHetStepNegative,
    InvalidHetStepTooLarge,
    InvalidHetStepNonNumeric,
    InvalidHetStepJob,
    JobTimeoutKilled,
    JobNodeFailKilled,
    EmptyList,
    GroupIdInvalid,
    GroupIdUnknown,
    UserIdInvalid,
    UserIdUnknown,
    InvalidAssoc,
    NodeAlreadyExists,
    NodeTableFull,
    InvalidRelativeQos,
    InvalidExtra,
    EspankGeneric,
    EspankBadArg,
    EspankNotTask,
    EspankEnvExists,
    EspankEnvNoexist,
    EspankNospace,
    EspankNotRemote,
    EspankNoexist,
    EspankNotExecd,
    EspankNotAvail,
    EspankNotLocal,
    SlurmdKillTaskFailed,
    SlurmdKillJobAlreadyComplete,
    SlurmdInvalidAcctFreq,
    SlurmdInvalidJobCredential,
    SlurmdCredentialExpired,
    SlurmdCredentialRevoked,
    SlurmdCredentialReplayed,
    SlurmdCreateBatchDir,
    SlurmdSetupEnvironment,
    SlurmdSetUidOrGid,
    SlurmdExecveFailed,
    SlurmdIo,
    SlurmdPrologFailed,
    SlurmdEpilogFailed,
    SlurmdToomanysteps,
    SlurmdStepExists,
    SlurmdJobNotrunning,
    SlurmdStepSuspended,
    SlurmdStepNotsuspended,
    SlurmdInvalidSocketNameLen,
    SlurmdContainerRuntimeInvalid,
    SlurmdCpuBind,
    SlurmdCpuLayout,
    ProtocolIncompletePacket,
    SlurmProtocolSocketImplTimeout,
    SlurmProtocolSocketZeroBytesSent,
    AuthCredInvalid,
    AuthBadarg,
    AuthUnpack,
    AuthSkip,
    AuthUnableToGenerateToken,
    DbConnection,
    JobsRunningOnAssoc,
    ClusterDeleted,
    OneChange,
    BadName,
    OverAllocate,
    ResultTooLarge,
    DbQueryTooWide,
    DbConnectionInvalid,
    NoRemoveDefaultAccount,
    BadSql,
    NoRemoveDefaultQos,
    FedClusterMaxCnt,
    FedClusterMultipleAssignment,
    InvalidClusterFeature,
    JobNotFederated,
    InvalidClusterName,
    FedJobLock,
    FedNoValidClusters,
    MissingTimeLimit,
    InvalidKnl,
    PluginInvalid,
    PluginIncomplete,
    PluginNotLoaded,
    PluginNotfound,
    PluginAccess,
    PluginDlopenFailed,
    PluginInitFailed,
    PluginMissingName,
    PluginBadVersion,
    RestInvalidQuery,
    RestFailParsing,
    RestInvalidJobsDesc,
    RestEmptyResult,
    RestMissingUid,
    RestMissingGid,
    DataPathNotFound,
    DataPtrNull,
    DataConvFailed,
    DataRegexCompile,
    DataUnknownMimeType,
    DataTooLarge,
    DataFlagsInvalidType,
    DataFlagsInvalid,
    DataExpectedList,
    DataExpectedDict,
    DataAmbiguousModify,
    DataAmbiguousQuery,
    DataParseNothing,
    DataInvalidParser,
    ContainerNotConfigured,
};

pub fn checkRpc(err: c_int) Error!void {
    return switch (err) {
        c.SLURM_SUCCESS => {},
        c.SLURM_ERROR => Error.Generic,
        c.SLURM_UNEXPECTED_MSG_ERROR => Error.UnexpectedMsg,
        c.SLURM_COMMUNICATIONS_CONNECTION_ERROR => Error.CommunicationsConnection,
        c.SLURM_COMMUNICATIONS_SEND_ERROR => Error.CommunicationsSend,
        c.SLURM_COMMUNICATIONS_RECEIVE_ERROR => Error.CommunicationsReceive,
        c.SLURM_COMMUNICATIONS_SHUTDOWN_ERROR => Error.CommunicationsShutdown,
        c.SLURM_PROTOCOL_VERSION_ERROR => Error.ProtocolVersion,
        c.SLURM_PROTOCOL_IO_STREAM_VERSION_ERROR => Error.ProtocolIoStreamVersion,
        c.SLURM_PROTOCOL_AUTHENTICATION_ERROR => Error.ProtocolAuthentication,
        c.SLURM_PROTOCOL_INSANE_MSG_LENGTH => Error.ProtocolInsaneMsgLength,
        c.SLURM_MPI_PLUGIN_NAME_INVALID => Error.MpiPluginNameInvalid,
        c.SLURM_MPI_PLUGIN_PRELAUNCH_SETUP_FAILED => Error.MpiPluginPrelaunchSetupFailed,
        c.SLURM_PLUGIN_NAME_INVALID => Error.PluginNameInvalid,
        c.SLURM_UNKNOWN_FORWARD_ADDR => Error.UnknownForwardAddr,
        c.SLURM_COMMUNICATIONS_MISSING_SOCKET_ERROR => Error.CommunicationsMissingSocket,
        c.SLURMCTLD_COMMUNICATIONS_CONNECTION_ERROR => Error.SlurmctldCommunicationsConnection,
        c.SLURMCTLD_COMMUNICATIONS_SEND_ERROR => Error.SlurmctldCommunicationsSend,
        c.SLURMCTLD_COMMUNICATIONS_RECEIVE_ERROR => Error.SlurmctldCommunicationsReceive,
        c.SLURMCTLD_COMMUNICATIONS_SHUTDOWN_ERROR => Error.SlurmctldCommunicationsShutdown,
        c.SLURMCTLD_COMMUNICATIONS_BACKOFF => Error.SlurmctldCommunicationsBackoff,
        c.SLURM_NO_CHANGE_IN_DATA => Error.NoChangeInData,
        c.ESLURM_INVALID_PARTITION_NAME => Error.InvalidPartitionName,
        c.ESLURM_DEFAULT_PARTITION_NOT_SET => Error.DefaultPartitionNotSet,
        c.ESLURM_ACCESS_DENIED => Error.AccessDenied,
        c.ESLURM_JOB_MISSING_REQUIRED_PARTITION_GROUP => Error.JobMissingRequiredPartitionGroup,
        c.ESLURM_REQUESTED_NODES_NOT_IN_PARTITION => Error.RequestedNodesNotInPartition,
        c.ESLURM_TOO_MANY_REQUESTED_CPUS => Error.TooManyRequestedCpus,
        c.ESLURM_INVALID_NODE_COUNT => Error.InvalidNodeCount,
        c.ESLURM_ERROR_ON_DESC_TO_RECORD_COPY => Error.OnDescToRecordCopy,
        c.ESLURM_JOB_MISSING_SIZE_SPECIFICATION => Error.JobMissingSizeSpecification,
        c.ESLURM_JOB_SCRIPT_MISSING => Error.JobScriptMissing,
        c.ESLURM_USER_ID_MISSING => Error.UserIdMissing,
        c.ESLURM_DUPLICATE_JOB_ID => Error.DuplicateJobId,
        c.ESLURM_PATHNAME_TOO_LONG => Error.PathnameTooLong,
        c.ESLURM_NOT_TOP_PRIORITY => Error.NotTopPriority,
        c.ESLURM_REQUESTED_NODE_CONFIG_UNAVAILABLE => Error.RequestedNodeConfigUnavailable,
        c.ESLURM_REQUESTED_PART_CONFIG_UNAVAILABLE => Error.RequestedPartConfigUnavailable,
        c.ESLURM_NODES_BUSY => Error.NodesBusy,
        c.ESLURM_INVALID_JOB_ID => Error.InvalidJobId,
        c.ESLURM_INVALID_NODE_NAME => Error.InvalidNodeName,
        c.ESLURM_WRITING_TO_FILE => Error.WritingToFile,
        c.ESLURM_TRANSITION_STATE_NO_UPDATE => Error.TransitionStateNoUpdate,
        c.ESLURM_ALREADY_DONE => Error.AlreadyDone,
        c.ESLURM_INTERCONNECT_FAILURE => Error.InterconnectFailure,
        c.ESLURM_BAD_DIST => Error.BadDist,
        c.ESLURM_JOB_PENDING => Error.JobPending,
        c.ESLURM_BAD_TASK_COUNT => Error.BadTaskCount,
        c.ESLURM_INVALID_JOB_CREDENTIAL => Error.InvalidJobCredential,
        c.ESLURM_IN_STANDBY_MODE => Error.InStandbyMode,
        c.ESLURM_INVALID_NODE_STATE => Error.InvalidNodeState,
        c.ESLURM_INVALID_FEATURE => Error.InvalidFeature,
        c.ESLURM_INVALID_AUTHTYPE_CHANGE => Error.InvalidAuthtypeChange,
        c.ESLURM_ACTIVE_FEATURE_NOT_SUBSET => Error.ActiveFeatureNotSubset,
        c.ESLURM_INVALID_SCHEDTYPE_CHANGE => Error.InvalidSchedtypeChange,
        c.ESLURM_INVALID_SELECTTYPE_CHANGE => Error.InvalidSelecttypeChange,
        c.ESLURM_INVALID_SWITCHTYPE_CHANGE => Error.InvalidSwitchtypeChange,
        c.ESLURM_FRAGMENTATION => Error.Fragmentation,
        c.ESLURM_NOT_SUPPORTED => Error.NotSupported,
        c.ESLURM_DISABLED => Error.Disabled,
        c.ESLURM_DEPENDENCY => Error.Dependency,
        c.ESLURM_BATCH_ONLY => Error.BatchOnly,
        c.ESLURM_LICENSES_UNAVAILABLE => Error.LicensesUnavailable,
        c.ESLURM_TAKEOVER_NO_HEARTBEAT => Error.TakeoverNoHeartbeat,
        c.ESLURM_JOB_HELD => Error.JobHeld,
        c.ESLURM_INVALID_CRED_TYPE_CHANGE => Error.InvalidCredTypeChange,
        c.ESLURM_INVALID_TASK_MEMORY => Error.InvalidTaskMemory,
        c.ESLURM_INVALID_ACCOUNT => Error.InvalidAccount,
        c.ESLURM_INVALID_PARENT_ACCOUNT => Error.InvalidParentAccount,
        c.ESLURM_SAME_PARENT_ACCOUNT => Error.SameParentAccount,
        c.ESLURM_INVALID_LICENSES => Error.InvalidLicenses,
        c.ESLURM_NEED_RESTART => Error.NeedRestart,
        c.ESLURM_ACCOUNTING_POLICY => Error.AccountingPolicy,
        c.ESLURM_INVALID_TIME_LIMIT => Error.InvalidTimeLimit,
        c.ESLURM_RESERVATION_ACCESS => Error.ReservationAccess,
        c.ESLURM_RESERVATION_INVALID => Error.ReservationInvalid,
        c.ESLURM_INVALID_TIME_VALUE => Error.InvalidTimeValue,
        c.ESLURM_RESERVATION_BUSY => Error.ReservationBusy,
        c.ESLURM_RESERVATION_NOT_USABLE => Error.ReservationNotUsable,
        c.ESLURM_INVALID_WCKEY => Error.InvalidWckey,
        c.ESLURM_RESERVATION_OVERLAP => Error.ReservationOverlap,
        c.ESLURM_PORTS_BUSY => Error.PortsBusy,
        c.ESLURM_PORTS_INVALID => Error.PortsInvalid,
        c.ESLURM_PROLOG_RUNNING => Error.PrologRunning,
        c.ESLURM_NO_STEPS => Error.NoSteps,
        c.ESLURM_MISSING_WORK_DIR => Error.MissingWorkDir,
        c.ESLURM_INVALID_QOS => Error.InvalidQos,
        c.ESLURM_QOS_PREEMPTION_LOOP => Error.QosPreemptionLoop,
        c.ESLURM_NODE_NOT_AVAIL => Error.NodeNotAvail,
        c.ESLURM_INVALID_CPU_COUNT => Error.InvalidCpuCount,
        c.ESLURM_PARTITION_NOT_AVAIL => Error.PartitionNotAvail,
        c.ESLURM_CIRCULAR_DEPENDENCY => Error.CircularDependency,
        c.ESLURM_INVALID_GRES => Error.InvalidGres,
        c.ESLURM_JOB_NOT_PENDING => Error.JobNotPending,
        c.ESLURM_QOS_THRES => Error.QosThres,
        c.ESLURM_PARTITION_IN_USE => Error.PartitionInUse,
        c.ESLURM_STEP_LIMIT => Error.StepLimit,
        c.ESLURM_JOB_SUSPENDED => Error.JobSuspended,
        c.ESLURM_CAN_NOT_START_IMMEDIATELY => Error.CanNotStartImmediately,
        c.ESLURM_INTERCONNECT_BUSY => Error.InterconnectBusy,
        c.ESLURM_RESERVATION_EMPTY => Error.ReservationEmpty,
        c.ESLURM_INVALID_ARRAY => Error.InvalidArray,
        c.ESLURM_RESERVATION_NAME_DUP => Error.ReservationNameDup,
        c.ESLURM_JOB_STARTED => Error.JobStarted,
        c.ESLURM_JOB_FINISHED => Error.JobFinished,
        c.ESLURM_JOB_NOT_RUNNING => Error.JobNotRunning,
        c.ESLURM_JOB_NOT_PENDING_NOR_RUNNING => Error.JobNotPendingNorRunning,
        c.ESLURM_JOB_NOT_SUSPENDED => Error.JobNotSuspended,
        c.ESLURM_JOB_NOT_FINISHED => Error.JobNotFinished,
        c.ESLURM_TRIGGER_DUP => Error.TriggerDup,
        c.ESLURM_INTERNAL => Error.Internal,
        c.ESLURM_INVALID_BURST_BUFFER_CHANGE => Error.InvalidBurstBufferChange,
        c.ESLURM_BURST_BUFFER_PERMISSION => Error.BurstBufferPermission,
        c.ESLURM_BURST_BUFFER_LIMIT => Error.BurstBufferLimit,
        c.ESLURM_INVALID_BURST_BUFFER_REQUEST => Error.InvalidBurstBufferRequest,
        c.ESLURM_PRIO_RESET_FAIL => Error.PrioResetFail,
        c.ESLURM_CANNOT_MODIFY_CRON_JOB => Error.CannotModifyCronJob,
        c.ESLURM_INVALID_JOB_CONTAINER_CHANGE => Error.InvalidJobContainerChange,
        c.ESLURM_CANNOT_CANCEL_CRON_JOB => Error.CannotCancelCronJob,
        c.ESLURM_INVALID_MCS_LABEL => Error.InvalidMcsLabel,
        c.ESLURM_BURST_BUFFER_WAIT => Error.BurstBufferWait,
        c.ESLURM_PARTITION_DOWN => Error.PartitionDown,
        c.ESLURM_DUPLICATE_GRES => Error.DuplicateGres,
        // c.ESLURM_JOB_SETTING_DB_INX => Error.JobSettingDbInx,
        c.ESLURM_RSV_ALREADY_STARTED => Error.RsvAlreadyStarted,
        c.ESLURM_SUBMISSIONS_DISABLED => Error.SubmissionsDisabled,
        c.ESLURM_NOT_HET_JOB => Error.NotHetJob,
        c.ESLURM_NOT_HET_JOB_LEADER => Error.NotHetJobLeader,
        c.ESLURM_NOT_WHOLE_HET_JOB => Error.NotWholeHetJob,
        c.ESLURM_CORE_RESERVATION_UPDATE => Error.CoreReservationUpdate,
        c.ESLURM_DUPLICATE_STEP_ID => Error.DuplicateStepId,
        c.ESLURM_INVALID_CORE_CNT => Error.InvalidCoreCnt,
        c.ESLURM_X11_NOT_AVAIL => Error.X11NotAvail,
        c.ESLURM_GROUP_ID_MISSING => Error.GroupIdMissing,
        c.ESLURM_BATCH_CONSTRAINT => Error.BatchConstraint,
        c.ESLURM_INVALID_TRES => Error.InvalidTres,
        c.ESLURM_INVALID_TRES_BILLING_WEIGHTS => Error.InvalidTresBillingWeights,
        c.ESLURM_INVALID_JOB_DEFAULTS => Error.InvalidJobDefaults,
        c.ESLURM_RESERVATION_MAINT => Error.ReservationMaint,
        c.ESLURM_INVALID_GRES_TYPE => Error.InvalidGresType,
        c.ESLURM_REBOOT_IN_PROGRESS => Error.RebootInProgress,
        c.ESLURM_MULTI_KNL_CONSTRAINT => Error.MultiKnlConstraint,
        c.ESLURM_UNSUPPORTED_GRES => Error.UnsupportedGres,
        c.ESLURM_INVALID_NICE => Error.InvalidNice,
        c.ESLURM_INVALID_TIME_MIN_LIMIT => Error.InvalidTimeMinLimit,
        c.ESLURM_DEFER => Error.Defer,
        c.ESLURM_CONFIGLESS_DISABLED => Error.ConfiglessDisabled,
        c.ESLURM_ENVIRONMENT_MISSING => Error.EnvironmentMissing,
        c.ESLURM_RESERVATION_NO_SKIP => Error.ReservationNoSkip,
        c.ESLURM_RESERVATION_USER_GROUP => Error.ReservationUserGroup,
        c.ESLURM_PARTITION_ASSOC => Error.PartitionAssoc,
        c.ESLURM_IN_STANDBY_USE_BACKUP => Error.InStandbyUseBackup,
        c.ESLURM_BAD_THREAD_PER_CORE => Error.BadThreadPerCore,
        c.ESLURM_INVALID_PREFER => Error.InvalidPrefer,
        c.ESLURM_INSUFFICIENT_GRES => Error.InsufficientGres,
        c.ESLURM_INVALID_CONTAINER_ID => Error.InvalidContainerId,
        c.ESLURM_EMPTY_JOB_ID => Error.EmptyJobId,
        c.ESLURM_INVALID_JOB_ID_ZERO => Error.InvalidJobIdZero,
        c.ESLURM_INVALID_JOB_ID_NEGATIVE => Error.InvalidJobIdNegative,
        c.ESLURM_INVALID_JOB_ID_TOO_LARGE => Error.InvalidJobIdTooLarge,
        c.ESLURM_INVALID_JOB_ID_NON_NUMERIC => Error.InvalidJobIdNonNumeric,
        c.ESLURM_EMPTY_JOB_ARRAY_ID => Error.EmptyJobArrayId,
        c.ESLURM_INVALID_JOB_ARRAY_ID_NEGATIVE => Error.InvalidJobArrayIdNegative,
        c.ESLURM_INVALID_JOB_ARRAY_ID_TOO_LARGE => Error.InvalidJobArrayIdTooLarge,
        c.ESLURM_INVALID_JOB_ARRAY_ID_NON_NUMERIC => Error.InvalidJobArrayIdNonNumeric,
        c.ESLURM_INVALID_HET_JOB_AND_ARRAY => Error.InvalidHetJobAndArray,
        c.ESLURM_EMPTY_HET_JOB_COMP => Error.EmptyHetJobComp,
        c.ESLURM_INVALID_HET_JOB_COMP_NEGATIVE => Error.InvalidHetJobCompNegative,
        c.ESLURM_INVALID_HET_JOB_COMP_TOO_LARGE => Error.InvalidHetJobCompTooLarge,
        c.ESLURM_INVALID_HET_JOB_COMP_NON_NUMERIC => Error.InvalidHetJobCompNonNumeric,
        c.ESLURM_EMPTY_STEP_ID => Error.EmptyStepId,
        c.ESLURM_INVALID_STEP_ID_NEGATIVE => Error.InvalidStepIdNegative,
        c.ESLURM_INVALID_STEP_ID_TOO_LARGE => Error.InvalidStepIdTooLarge,
        c.ESLURM_INVALID_STEP_ID_NON_NUMERIC => Error.InvalidStepIdNonNumeric,
        c.ESLURM_EMPTY_HET_STEP => Error.EmptyHetStep,
        c.ESLURM_INVALID_HET_STEP_ZERO => Error.InvalidHetStepZero,
        c.ESLURM_INVALID_HET_STEP_NEGATIVE => Error.InvalidHetStepNegative,
        c.ESLURM_INVALID_HET_STEP_TOO_LARGE => Error.InvalidHetStepTooLarge,
        c.ESLURM_INVALID_HET_STEP_NON_NUMERIC => Error.InvalidHetStepNonNumeric,
        c.ESLURM_INVALID_HET_STEP_JOB => Error.InvalidHetStepJob,
        c.ESLURM_JOB_TIMEOUT_KILLED => Error.JobTimeoutKilled,
        c.ESLURM_JOB_NODE_FAIL_KILLED => Error.JobNodeFailKilled,
        c.ESLURM_EMPTY_LIST => Error.EmptyList,
        c.ESLURM_GROUP_ID_INVALID => Error.GroupIdInvalid,
        c.ESLURM_GROUP_ID_UNKNOWN => Error.GroupIdUnknown,
        c.ESLURM_USER_ID_INVALID => Error.UserIdInvalid,
        c.ESLURM_USER_ID_UNKNOWN => Error.UserIdUnknown,
        c.ESLURM_INVALID_ASSOC => Error.InvalidAssoc,
        c.ESLURM_NODE_ALREADY_EXISTS => Error.NodeAlreadyExists,
        c.ESLURM_NODE_TABLE_FULL => Error.NodeTableFull,
        c.ESLURM_INVALID_RELATIVE_QOS => Error.InvalidRelativeQos,
        c.ESLURM_INVALID_EXTRA => Error.InvalidExtra,
        c.ESPANK_ERROR => Error.EspankGeneric,
        c.ESPANK_BAD_ARG => Error.EspankBadArg,
        c.ESPANK_NOT_TASK => Error.EspankNotTask,
        c.ESPANK_ENV_EXISTS => Error.EspankEnvExists,
        c.ESPANK_ENV_NOEXIST => Error.EspankEnvNoexist,
        c.ESPANK_NOSPACE => Error.EspankNospace,
        c.ESPANK_NOT_REMOTE => Error.EspankNotRemote,
        c.ESPANK_NOEXIST => Error.EspankNoexist,
        c.ESPANK_NOT_EXECD => Error.EspankNotExecd,
        c.ESPANK_NOT_AVAIL => Error.EspankNotAvail,
        c.ESPANK_NOT_LOCAL => Error.EspankNotLocal,
        c.ESLURMD_KILL_TASK_FAILED => Error.SlurmdKillTaskFailed,
        c.ESLURMD_KILL_JOB_ALREADY_COMPLETE => Error.SlurmdKillJobAlreadyComplete,
        c.ESLURMD_INVALID_ACCT_FREQ => Error.SlurmdInvalidAcctFreq,
        c.ESLURMD_INVALID_JOB_CREDENTIAL => Error.SlurmdInvalidJobCredential,
        c.ESLURMD_CREDENTIAL_EXPIRED => Error.SlurmdCredentialExpired,
        c.ESLURMD_CREDENTIAL_REVOKED => Error.SlurmdCredentialRevoked,
        c.ESLURMD_CREDENTIAL_REPLAYED => Error.SlurmdCredentialReplayed,
        c.ESLURMD_CREATE_BATCH_DIR_ERROR => Error.SlurmdCreateBatchDir,
        c.ESLURMD_SETUP_ENVIRONMENT_ERROR => Error.SlurmdSetupEnvironment,
        c.ESLURMD_SET_UID_OR_GID_ERROR => Error.SlurmdSetUidOrGid,
        c.ESLURMD_EXECVE_FAILED => Error.SlurmdExecveFailed,
        c.ESLURMD_IO_ERROR => Error.SlurmdIo,
        c.ESLURMD_PROLOG_FAILED => Error.SlurmdPrologFailed,
        c.ESLURMD_EPILOG_FAILED => Error.SlurmdEpilogFailed,
        c.ESLURMD_TOOMANYSTEPS => Error.SlurmdToomanysteps,
        c.ESLURMD_STEP_EXISTS => Error.SlurmdStepExists,
        c.ESLURMD_JOB_NOTRUNNING => Error.SlurmdJobNotrunning,
        c.ESLURMD_STEP_SUSPENDED => Error.SlurmdStepSuspended,
        c.ESLURMD_STEP_NOTSUSPENDED => Error.SlurmdStepNotsuspended,
        c.ESLURMD_INVALID_SOCKET_NAME_LEN => Error.SlurmdInvalidSocketNameLen,
        c.ESLURMD_CONTAINER_RUNTIME_INVALID => Error.SlurmdContainerRuntimeInvalid,
        c.ESLURMD_CPU_BIND_ERROR => Error.SlurmdCpuBind,
        c.ESLURMD_CPU_LAYOUT_ERROR => Error.SlurmdCpuLayout,
        c.ESLURM_PROTOCOL_INCOMPLETE_PACKET => Error.ProtocolIncompletePacket,
        c.SLURM_PROTOCOL_SOCKET_IMPL_TIMEOUT => Error.SlurmProtocolSocketImplTimeout,
        c.SLURM_PROTOCOL_SOCKET_ZERO_BYTES_SENT => Error.SlurmProtocolSocketZeroBytesSent,
        c.ESLURM_AUTH_CRED_INVALID => Error.AuthCredInvalid,
        c.ESLURM_AUTH_BADARG => Error.AuthBadarg,
        c.ESLURM_AUTH_UNPACK => Error.AuthUnpack,
        c.ESLURM_AUTH_SKIP => Error.AuthSkip,
        c.ESLURM_AUTH_UNABLE_TO_GENERATE_TOKEN => Error.AuthUnableToGenerateToken,
        c.ESLURM_DB_CONNECTION => Error.DbConnection,
        c.ESLURM_JOBS_RUNNING_ON_ASSOC => Error.JobsRunningOnAssoc,
        c.ESLURM_CLUSTER_DELETED => Error.ClusterDeleted,
        c.ESLURM_ONE_CHANGE => Error.OneChange,
        c.ESLURM_BAD_NAME => Error.BadName,
        c.ESLURM_OVER_ALLOCATE => Error.OverAllocate,
        c.ESLURM_RESULT_TOO_LARGE => Error.ResultTooLarge,
        c.ESLURM_DB_QUERY_TOO_WIDE => Error.DbQueryTooWide,
        c.ESLURM_DB_CONNECTION_INVALID => Error.DbConnectionInvalid,
        c.ESLURM_NO_REMOVE_DEFAULT_ACCOUNT => Error.NoRemoveDefaultAccount,
        c.ESLURM_BAD_SQL => Error.BadSql,
        c.ESLURM_NO_REMOVE_DEFAULT_QOS => Error.NoRemoveDefaultQos,
        c.ESLURM_FED_CLUSTER_MAX_CNT => Error.FedClusterMaxCnt,
        c.ESLURM_FED_CLUSTER_MULTIPLE_ASSIGNMENT => Error.FedClusterMultipleAssignment,
        c.ESLURM_INVALID_CLUSTER_FEATURE => Error.InvalidClusterFeature,
        c.ESLURM_JOB_NOT_FEDERATED => Error.JobNotFederated,
        c.ESLURM_INVALID_CLUSTER_NAME => Error.InvalidClusterName,
        c.ESLURM_FED_JOB_LOCK => Error.FedJobLock,
        c.ESLURM_FED_NO_VALID_CLUSTERS => Error.FedNoValidClusters,
        c.ESLURM_MISSING_TIME_LIMIT => Error.MissingTimeLimit,
        c.ESLURM_INVALID_KNL => Error.InvalidKnl,
        c.ESLURM_PLUGIN_INVALID => Error.PluginInvalid,
        c.ESLURM_PLUGIN_INCOMPLETE => Error.PluginIncomplete,
        c.ESLURM_PLUGIN_NOT_LOADED => Error.PluginNotLoaded,
        c.ESLURM_PLUGIN_NOTFOUND => Error.PluginNotfound,
        c.ESLURM_PLUGIN_ACCESS_ERROR => Error.PluginAccess,
        c.ESLURM_PLUGIN_DLOPEN_FAILED => Error.PluginDlopenFailed,
        c.ESLURM_PLUGIN_INIT_FAILED => Error.PluginInitFailed,
        c.ESLURM_PLUGIN_MISSING_NAME => Error.PluginMissingName,
        c.ESLURM_PLUGIN_BAD_VERSION => Error.PluginBadVersion,
        c.ESLURM_REST_INVALID_QUERY => Error.RestInvalidQuery,
        c.ESLURM_REST_FAIL_PARSING => Error.RestFailParsing,
        c.ESLURM_REST_INVALID_JOBS_DESC => Error.RestInvalidJobsDesc,
        c.ESLURM_REST_EMPTY_RESULT => Error.RestEmptyResult,
        c.ESLURM_REST_MISSING_UID => Error.RestMissingUid,
        c.ESLURM_REST_MISSING_GID => Error.RestMissingGid,
        c.ESLURM_DATA_PATH_NOT_FOUND => Error.DataPathNotFound,
        c.ESLURM_DATA_PTR_NULL => Error.DataPtrNull,
        c.ESLURM_DATA_CONV_FAILED => Error.DataConvFailed,
        c.ESLURM_DATA_REGEX_COMPILE => Error.DataRegexCompile,
        c.ESLURM_DATA_UNKNOWN_MIME_TYPE => Error.DataUnknownMimeType,
        c.ESLURM_DATA_TOO_LARGE => Error.DataTooLarge,
        c.ESLURM_DATA_FLAGS_INVALID_TYPE => Error.DataFlagsInvalidType,
        c.ESLURM_DATA_FLAGS_INVALID => Error.DataFlagsInvalid,
        c.ESLURM_DATA_EXPECTED_LIST => Error.DataExpectedList,
        c.ESLURM_DATA_EXPECTED_DICT => Error.DataExpectedDict,
        c.ESLURM_DATA_AMBIGUOUS_MODIFY => Error.DataAmbiguousModify,
        c.ESLURM_DATA_AMBIGUOUS_QUERY => Error.DataAmbiguousQuery,
        c.ESLURM_DATA_PARSE_NOTHING => Error.DataParseNothing,
        c.ESLURM_DATA_INVALID_PARSER => Error.DataInvalidParser,
        c.ESLURM_CONTAINER_NOT_CONFIGURED => Error.ContainerNotConfigured,
        else => Error.Generic,
    };
}

test "getErrorString" {
    try std.testing.expect(getErrorString() != null);
}

test "getError" {
    try getError();
}

test "getErrorBundle" {
    _ = getErrorBundle();
}
