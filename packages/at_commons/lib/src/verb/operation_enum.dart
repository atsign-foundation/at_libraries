enum OperationEnum { update, delete, append, remove }

String getOperationName(OperationEnum? d) => '$d'.split('.').last;

enum PriorityEnum { low, medium, high }

String getPriority(PriorityEnum? priorityEnum) =>
    '$priorityEnum'.split('.').last;

enum StrategyEnum { all, latest }

String getStrategy(StrategyEnum? strategyEnum) =>
    '$strategyEnum'.split('.').last;

enum MessageTypeEnum { key, text }

String getMessageType(MessageTypeEnum? messageTypeEnum) =>
    '$messageTypeEnum'.split('.').last;

enum EnrollOperationEnum { request, approve, deny, revoke, list, update }

String getEnrollOperation(EnrollOperationEnum? enrollOperationEnum) =>
    '$enrollOperationEnum'.split('.').last;
