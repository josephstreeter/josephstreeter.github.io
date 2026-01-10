---
title: Asyncio - Asynchronous Programming in Python
description: Comprehensive guide to asyncio, Python's built-in library for writing concurrent code using async/await syntax, coroutines, and event loops
---

Asyncio is Python's built-in library for writing asynchronous, concurrent code using the async/await syntax. It provides a foundation for writing single-threaded concurrent programs using coroutines, multiplexing I/O operations, and running network clients and servers with high performance and scalability.

## Overview

Asyncio represents a fundamental shift in how Python handles concurrent operations. Rather than using threads or processes, asyncio uses cooperative multitasking with an event loop to manage multiple operations concurrently within a single thread. This approach is particularly efficient for I/O-bound operations, network programming, and applications that need to handle many concurrent connections.

The library provides:

- **Coroutines**: Functions that can be paused and resumed, allowing other code to run during waiting periods
- **Event Loop**: Central execution engine that manages and schedules coroutines
- **Tasks**: Wrapper objects that schedule coroutines to run on the event loop
- **Futures**: Low-level objects representing eventual results of asynchronous operations
- **Synchronization Primitives**: Locks, events, semaphores, and queues for coordinating async code
- **Network Protocol Support**: High-level APIs for streams and low-level APIs for protocols

## Installation

Asyncio is included in the Python standard library starting with Python 3.4, with significant improvements in Python 3.7+. No installation required.

```python
import asyncio
```

**Recommended Python Version**: Python 3.7 or higher for the modern async/await syntax and `asyncio.run()` function.

**Version Compatibility**:

- Python 3.4-3.6: Basic asyncio support (legacy)
- Python 3.7+: Modern asyncio with `asyncio.run()` and improved APIs
- Python 3.10+: Enhanced error messages and performance improvements
- Python 3.11+: Task groups and exception groups

## Basic Concepts

### Coroutines

Coroutines are special functions defined with `async def` that can be paused and resumed, allowing other code to run during waiting periods. They are the foundation of asyncio programming.

#### Defining Coroutines

```python
import asyncio

async def GreetUser(Name: str) -> str:
    """
    Simple coroutine that greets a user.
    
    Args:
        Name: User's name
        
    Returns:
        Greeting message
    """
    await asyncio.sleep(1)  # Simulate I/O operation
    return f"Hello, {Name}!"

# Run the coroutine
Result = asyncio.run(GreetUser("Alice"))
print(Result)  # Hello, Alice!
```

#### Awaiting Coroutines

The `await` keyword is used to wait for a coroutine to complete:

```python
async def FetchData(Url: str) -> dict:
    """Simulate fetching data from a URL"""
    await asyncio.sleep(2)  # Simulate network delay
    return {"url": Url, "data": "sample"}

async def ProcessData():
    """Process data from multiple sources"""
    # Sequential execution
    Data1 = await FetchData("https://api.example.com/1")
    Data2 = await FetchData("https://api.example.com/2")
    
    print(f"Received: {Data1}, {Data2}")

asyncio.run(ProcessData())
```

#### Coroutine Objects

Calling an async function returns a coroutine object, not the result:

```python
async def GetNumber() -> int:
    return 42

# This creates a coroutine object, doesn't execute the function
CoroutineObj = GetNumber()
print(type(CoroutineObj))  # <class 'coroutine'>

# To execute, you must await it or run it
Result = asyncio.run(GetNumber())
print(Result)  # 42
```

### Event Loop

The event loop is the core of asyncio, managing and executing asynchronous tasks. It runs coroutines, handles I/O operations, and schedules callbacks.

#### Using asyncio.run()

The simplest way to run async code (Python 3.7+):

```python
import asyncio

async def Main():
    """Entry point for async application"""
    print("Starting application")
    await asyncio.sleep(1)
    print("Application complete")

# asyncio.run() creates event loop, runs coroutine, and closes loop
asyncio.run(Main())
```

#### Manual Event Loop Management

For more control (rarely needed):

```python
import asyncio

async def Task():
    await asyncio.sleep(1)
    return "Done"

# Manual loop management
Loop = asyncio.new_event_loop()
asyncio.set_event_loop(Loop)

try:
    Result = Loop.run_until_complete(Task())
    print(Result)
finally:
    Loop.close()
```

#### Getting the Current Event Loop

```python
async def ShowLoop():
    """Display information about the current event loop"""
    Loop = asyncio.get_running_loop()
    print(f"Loop: {Loop}")
    print(f"Is running: {Loop.is_running()}")

asyncio.run(ShowLoop())
```

### Tasks

Tasks are used to schedule coroutines to run concurrently on the event loop. They wrap coroutines and provide methods to cancel, check status, and retrieve results.

#### Creating Tasks

```python
import asyncio

async def DoWork(TaskId: int, Duration: float) -> str:
    """Simulate work with a duration"""
    print(f"Task {TaskId} started")
    await asyncio.sleep(Duration)
    print(f"Task {TaskId} completed")
    return f"Result from task {TaskId}"

async def Main():
    """Create and run multiple tasks concurrently"""
    # Create tasks - they start immediately
    Task1 = asyncio.create_task(DoWork(1, 2))
    Task2 = asyncio.create_task(DoWork(2, 1))
    Task3 = asyncio.create_task(DoWork(3, 1.5))
    
    # Wait for all tasks to complete
    Results = await asyncio.gather(Task1, Task2, Task3)
    print(f"All results: {Results}")

asyncio.run(Main())
```

#### Task Names and Tracking

```python
async def NamedTask(Data: str) -> str:
    """Task with a descriptive name"""
    await asyncio.sleep(1)
    return f"Processed: {Data}"

async def Main():
    """Create tasks with names for easier debugging"""
    Task = asyncio.create_task(
        NamedTask("user_data"),
        name="process_user_data"
    )
    
    print(f"Task name: {Task.get_name()}")
    print(f"Task done: {Task.done()}")
    
    Result = await Task
    print(f"Result: {Result}")

asyncio.run(Main())
```

#### Canceling Tasks

```python
import asyncio

async def LongRunningTask():
    """Task that can be canceled"""
    try:
        print("Task started")
        await asyncio.sleep(10)
        print("Task completed")
    except asyncio.CancelledError:
        print("Task was canceled")
        raise  # Re-raise to properly handle cancellation

async def Main():
    """Demonstrate task cancellation"""
    Task = asyncio.create_task(LongRunningTask())
    
    # Let it run briefly
    await asyncio.sleep(1)
    
    # Cancel the task
    Task.cancel()
    
    try:
        await Task
    except asyncio.CancelledError:
        print("Main caught cancellation")

asyncio.run(Main())
```

### Futures

Futures are low-level objects representing the result of an asynchronous operation. Tasks are actually subclasses of Future. You typically work with Tasks rather than Futures directly.

```python
import asyncio

async def WorkWithFuture():
    """Demonstrate Future usage"""
    Loop = asyncio.get_running_loop()
    
    # Create a future
    Future = Loop.create_future()
    
    # Set result after a delay
    async def SetResult():
        await asyncio.sleep(1)
        Future.set_result("Future result")
    
    # Schedule the result setter
    asyncio.create_task(SetResult())
    
    # Wait for the future
    Result = await Future
    print(f"Got: {Result}")

asyncio.run(WorkWithFuture())
```

### Async Context Managers

Async context managers use `async with` for asynchronous setup and teardown:

```python
import asyncio

class AsyncDatabaseConnection:
    """Example async context manager"""
    
    async def __aenter__(self):
        """Called when entering the context"""
        print("Opening database connection")
        await asyncio.sleep(0.5)  # Simulate connection setup
        self.Connection = "DB Connection"
        return self
    
    async def __aexit__(self, ExcType, ExcVal, ExcTb):
        """Called when exiting the context"""
        print("Closing database connection")
        await asyncio.sleep(0.5)  # Simulate cleanup
        self.Connection = None
    
    async def Query(self, Sql: str) -> list:
        """Execute a query"""
        await asyncio.sleep(0.1)
        return [{"id": 1, "name": "test"}]

async def UseDatabase():
    """Use the async context manager"""
    async with AsyncDatabaseConnection() as Db:
        Results = await Db.Query("SELECT * FROM users")
        print(f"Query results: {Results}")
    # Connection automatically closed here

asyncio.run(UseDatabase())
```

### Async Iterators

Async iterators use `async for` to iterate over asynchronous sequences:

```python
import asyncio

class AsyncRange:
    """Async iterator that yields numbers with delays"""
    
    def __init__(self, Count: int):
        self.Count = Count
        self.Current = 0
    
    def __aiter__(self):
        """Return the async iterator object"""
        return self
    
    async def __anext__(self):
        """Get the next item asynchronously"""
        if self.Current >= self.Count:
            raise StopAsyncIteration
        
        await asyncio.sleep(0.5)  # Simulate async operation
        self.Current += 1
        return self.Current

async def UseAsyncIterator():
    """Iterate over async sequence"""
    print("Starting iteration:")
    async for Number in AsyncRange(5):
        print(f"  Got: {Number}")

asyncio.run(UseAsyncIterator())
```

#### Async Generators

Simpler way to create async iterators:

```python
import asyncio

async def FetchItems(Count: int):
    """Async generator that yields items"""
    for I in range(Count):
        await asyncio.sleep(0.5)  # Simulate fetching
        yield f"Item {I + 1}"

async def ConsumeItems():
    """Consume items from async generator"""
    async for Item in FetchItems(3):
        print(f"Processing: {Item}")

asyncio.run(ConsumeItems())
```

## Common Patterns

### Running Multiple Coroutines Concurrently

#### Using asyncio.gather()

Run multiple coroutines concurrently and collect results:

```python
import asyncio
import time

async def FetchUrl(Url: str, Delay: float) -> dict:
    """Simulate fetching data from a URL"""
    print(f"Fetching {Url}")
    await asyncio.sleep(Delay)
    return {"url": Url, "status": 200}

async def FetchAllUrls():
    """Fetch multiple URLs concurrently"""
    StartTime = time.time()
    
    # Run all coroutines concurrently
    Results = await asyncio.gather(
        FetchUrl("https://api.example.com/users", 2),
        FetchUrl("https://api.example.com/posts", 1),
        FetchUrl("https://api.example.com/comments", 1.5)
    )
    
    ElapsedTime = time.time() - StartTime
    print(f"Completed in {ElapsedTime:.2f} seconds")
    print(f"Results: {Results}")
    # Completes in ~2 seconds (longest task) instead of 4.5 seconds sequentially

asyncio.run(FetchAllUrls())
```

#### gather() with Error Handling

```python
import asyncio

async def TaskThatFails():
    """Task that raises an exception"""
    await asyncio.sleep(1)
    raise ValueError("Task failed!")

async def TaskThatSucceeds():
    """Task that completes successfully"""
    await asyncio.sleep(1)
    return "Success"

async def HandleErrors():
    """Handle errors from gather()"""
    try:
        # return_exceptions=False (default): raises first exception
        Results = await asyncio.gather(
            TaskThatSucceeds(),
            TaskThatFails(),
            return_exceptions=False
        )
    except ValueError as E:
        print(f"Caught error: {E}")
    
    # return_exceptions=True: returns exceptions as values
    Results = await asyncio.gather(
        TaskThatSucceeds(),
        TaskThatFails(),
        return_exceptions=True
    )
    
    for I, Result in enumerate(Results):
        if isinstance(Result, Exception):
            print(f"Task {I} failed: {Result}")
        else:
            print(f"Task {I} succeeded: {Result}")

asyncio.run(HandleErrors())
```

#### Using asyncio.create_task()

Create tasks for more control:

```python
import asyncio

async def ProcessItem(ItemId: int) -> str:
    """Process a single item"""
    await asyncio.sleep(1)
    return f"Processed item {ItemId}"

async def ProcessAllItems():
    """Process multiple items with task management"""
    # Create all tasks
    Tasks = []
    for ItemId in range(5):
        Task = asyncio.create_task(ProcessItem(ItemId))
        Tasks.append(Task)
    
    # Wait for all tasks
    Results = await asyncio.gather(*Tasks)
    print(f"All results: {Results}")

asyncio.run(ProcessAllItems())
```

#### Using asyncio.as_completed()

Process results as they complete:

```python
import asyncio

async def FetchData(Source: str, Delay: float) -> str:
    """Fetch data with varying delays"""
    await asyncio.sleep(Delay)
    return f"Data from {Source}"

async def ProcessAsCompleted():
    """Process results as they become available"""
    Coroutines = [
        FetchData("API-A", 3),
        FetchData("API-B", 1),
        FetchData("API-C", 2)
    ]
    
    # Process in completion order, not submission order
    for CoroutineDone in asyncio.as_completed(Coroutines):
        Result = await CoroutineDone
        print(f"Got: {Result}")
    # Output order: API-B (1s), API-C (2s), API-A (3s)

asyncio.run(ProcessAsCompleted())
```

### Timeouts and Cancellation

#### Using asyncio.wait_for()

Set timeout for a coroutine:

```python
import asyncio

async def SlowOperation() -> str:
    """Operation that takes a while"""
    await asyncio.sleep(5)
    return "Done"

async def WithTimeout():
    """Run operation with timeout"""
    try:
        Result = await asyncio.wait_for(SlowOperation(), timeout=2.0)
        print(f"Result: {Result}")
    except asyncio.TimeoutError:
        print("Operation timed out!")

asyncio.run(WithTimeout())
```

#### Timeout with asyncio.timeout() (Python 3.11+)

```python
import asyncio

async def LongTask() -> str:
    """Task that takes time"""
    await asyncio.sleep(10)
    return "Completed"

async def UseTimeout():
    """Use timeout context manager"""
    try:
        async with asyncio.timeout(3):
            Result = await LongTask()
            print(f"Result: {Result}")
    except asyncio.TimeoutError:
        print("Task exceeded timeout")

# Python 3.11+
# asyncio.run(UseTimeout())
```

#### Manual Cancellation

```python
import asyncio

async def BackgroundTask():
    """Task that runs in background"""
    try:
        while True:
            print("Working...")
            await asyncio.sleep(1)
    except asyncio.CancelledError:
        print("Task canceled, cleaning up")
        # Perform cleanup
        raise

async def ManageTask():
    """Start and cancel background task"""
    Task = asyncio.create_task(BackgroundTask())
    
    # Let it run for a while
    await asyncio.sleep(3)
    
    # Cancel it
    Task.cancel()
    
    try:
        await Task
    except asyncio.CancelledError:
        print("Confirmed task canceled")

asyncio.run(ManageTask())
```

### Waiting for Multiple Tasks

#### asyncio.wait()

More control over completion:

```python
import asyncio

async def Task(TaskId: int, Duration: float) -> int:
    """Simple task with duration"""
    await asyncio.sleep(Duration)
    return TaskId

async def WaitForTasks():
    """Wait for tasks with different strategies"""
    Tasks = [
        asyncio.create_task(Task(1, 2)),
        asyncio.create_task(Task(2, 1)),
        asyncio.create_task(Task(3, 3))
    ]
    
    # Wait for first task to complete
    Done, Pending = await asyncio.wait(
        Tasks,
        return_when=asyncio.FIRST_COMPLETED
    )
    
    print(f"First completed: {Done}")
    print(f"Still pending: {len(Pending)}")
    
    # Cancel remaining tasks
    for Task in Pending:
        Task.cancel()
    
    # Wait for cancellation to complete
    await asyncio.wait(Pending)

asyncio.run(WaitForTasks())
```

#### Wait Strategies

```python
import asyncio

async def DemoWaitStrategies():
    """Demonstrate different wait strategies"""
    Tasks = [
        asyncio.create_task(asyncio.sleep(I))
        for I in range(1, 4)
    ]
    
    # FIRST_COMPLETED: return when first task completes
    Done, Pending = await asyncio.wait(
        Tasks,
        return_when=asyncio.FIRST_COMPLETED
    )
    
    # FIRST_EXCEPTION: return when first task raises exception
    # ALL_COMPLETED: wait for all tasks (default)
    
    print(f"Done: {len(Done)}, Pending: {len(Pending)}")

asyncio.run(DemoWaitStrategies())
```

### Task Groups (Python 3.11+)

Modern way to manage groups of tasks:

```python
import asyncio

async def ProcessBatch(BatchId: int) -> str:
    """Process a batch of data"""
    await asyncio.sleep(1)
    if BatchId == 2:
        raise ValueError(f"Batch {BatchId} failed")
    return f"Batch {BatchId} done"

async def UseTaskGroup():
    """Use task group for structured concurrency"""
    try:
        async with asyncio.TaskGroup() as Group:
            Task1 = Group.create_task(ProcessBatch(1))
            Task2 = Group.create_task(ProcessBatch(2))
            Task3 = Group.create_task(ProcessBatch(3))
        
        # All tasks completed successfully
        print("All batches processed")
    except ExceptionGroup as Eg:
        print(f"Some tasks failed: {Eg}")

# Python 3.11+
# asyncio.run(UseTaskGroup())
```

### Synchronization Between Coroutines

#### Using asyncio.Queue

Producer-consumer pattern:

```python
import asyncio
from typing import Optional

async def Producer(Queue: asyncio.Queue, ProducerId: int):
    """Produce items and add to queue"""
    for I in range(5):
        Item = f"Item-{ProducerId}-{I}"
        await Queue.put(Item)
        print(f"Producer {ProducerId} added: {Item}")
        await asyncio.sleep(0.5)
    
    await Queue.put(None)  # Signal completion

async def Consumer(Queue: asyncio.Queue, ConsumerId: int):
    """Consume items from queue"""
    while True:
        Item = await Queue.get()
        
        if Item is None:
            Queue.task_done()
            break
        
        print(f"Consumer {ConsumerId} processing: {Item}")
        await asyncio.sleep(1)  # Simulate processing
        Queue.task_done()

async def ProducerConsumer():
    """Run producer-consumer pattern"""
    Queue = asyncio.Queue(maxsize=10)
    
    # Create producers and consumers
    Producers = [
        asyncio.create_task(Producer(Queue, I))
        for I in range(2)
    ]
    
    Consumers = [
        asyncio.create_task(Consumer(Queue, I))
        for I in range(3)
    ]
    
    # Wait for producers
    await asyncio.gather(*Producers)
    
    # Wait for queue to be empty
    await Queue.join()
    
    # Cancel consumers
    for Consumer in Consumers:
        Consumer.cancel()

asyncio.run(ProducerConsumer())
```

## Working with I/O

### Network Operations

#### HTTP Client with aiohttp

While asyncio provides low-level network support, third-party libraries like `aiohttp` are commonly used:

```bash
pip install aiohttp
```

```python
import asyncio
import aiohttp

async def FetchUrl(Session: aiohttp.ClientSession, Url: str) -> dict:
    """Fetch URL content"""
    async with Session.get(Url) as Response:
        return {
            "url": Url,
            "status": Response.status,
            "content_length": len(await Response.text())
        }

async def FetchMultipleUrls():
    """Fetch multiple URLs concurrently"""
    Urls = [
        "https://httpbin.org/delay/1",
        "https://httpbin.org/delay/2",
        "https://httpbin.org/delay/1"
    ]
    
    async with aiohttp.ClientSession() as Session:
        Tasks = [FetchUrl(Session, Url) for Url in Urls]
        Results = await asyncio.gather(*Tasks)
        
        for Result in Results:
            print(f"{Result['url']}: {Result['status']}")

asyncio.run(FetchMultipleUrls())
```

#### TCP Server and Client

Low-level TCP using asyncio streams:

```python
import asyncio

async def HandleClient(Reader: asyncio.StreamReader, 
                       Writer: asyncio.StreamWriter):
    """Handle a client connection"""
    Address = Writer.get_extra_info('peername')
    print(f"Connection from {Address}")
    
    try:
        while True:
            Data = await Reader.read(100)
            if not Data:
                break
            
            Message = Data.decode()
            print(f"Received: {Message}")
            
            # Echo back
            Writer.write(f"Echo: {Message}".encode())
            await Writer.drain()
    finally:
        Writer.close()
        await Writer.wait_closed()
        print(f"Closed connection from {Address}")

async def RunServer():
    """Start TCP server"""
    Server = await asyncio.start_server(
        HandleClient,
        '127.0.0.1',
        8888
    )
    
    Address = Server.sockets[0].getsockname()
    print(f"Server running on {Address}")
    
    async with Server:
        await Server.serve_forever()

# Run server: asyncio.run(RunServer())
```

TCP Client:

```python
import asyncio

async def TcpClient():
    """Connect to TCP server and send messages"""
    Reader, Writer = await asyncio.open_connection(
        '127.0.0.1',
        8888
    )
    
    try:
        # Send message
        Message = "Hello Server!"
        Writer.write(Message.encode())
        await Writer.drain()
        
        # Receive response
        Data = await Reader.read(100)
        print(f"Received: {Data.decode()}")
    finally:
        Writer.close()
        await Writer.wait_closed()

asyncio.run(TcpClient())
```

### File Operations

#### Async File I/O with aiofiles

```bash
pip install aiofiles
```

```python
import asyncio
import aiofiles

async def ReadFile(FileName: str) -> str:
    """Read file asynchronously"""
    async with aiofiles.open(FileName, mode='r') as File:
        Contents = await File.read()
        return Contents

async def WriteFile(FileName: str, Content: str):
    """Write file asynchronously"""
    async with aiofiles.open(FileName, mode='w') as File:
        await File.write(Content)

async def ProcessFiles():
    """Read and write files concurrently"""
    # Write files concurrently
    await asyncio.gather(
        WriteFile('file1.txt', 'Content 1'),
        WriteFile('file2.txt', 'Content 2'),
        WriteFile('file3.txt', 'Content 3')
    )
    
    # Read files concurrently
    Contents = await asyncio.gather(
        ReadFile('file1.txt'),
        ReadFile('file2.txt'),
        ReadFile('file3.txt')
    )
    
    for Content in Contents:
        print(Content)

asyncio.run(ProcessFiles())
```

#### File Processing Pattern

```python
import asyncio
import aiofiles
from pathlib import Path

async def ProcessTextFile(FilePath: Path) -> dict:
    """Process a text file and return statistics"""
    async with aiofiles.open(FilePath, mode='r') as File:
        Content = await File.read()
        return {
            "file": FilePath.name,
            "lines": len(Content.splitlines()),
            "words": len(Content.split()),
            "chars": len(Content)
        }

async def ProcessDirectory(DirPath: Path):
    """Process all text files in directory"""
    TextFiles = list(DirPath.glob('*.txt'))
    
    Tasks = [ProcessTextFile(File) for File in TextFiles]
    Results = await asyncio.gather(*Tasks)
    
    for Stats in Results:
        print(f"{Stats['file']}: {Stats['lines']} lines, "
              f"{Stats['words']} words")

asyncio.run(ProcessDirectory(Path('.')))
```

### Database Operations

#### Async Database with asyncpg (PostgreSQL)

```bash
pip install asyncpg
```

```python
import asyncio
import asyncpg

async def FetchUsers():
    """Fetch users from database"""
    Connection = await asyncpg.connect(
        user='user',
        password='password',
        database='mydb',
        host='localhost'
    )
    
    try:
        # Fetch all users
        Rows = await Connection.fetch(
            'SELECT id, name, email FROM users WHERE active = $1',
            True
        )
        
        for Row in Rows:
            print(f"User: {Row['name']} ({Row['email']})")
    finally:
        await Connection.close()

asyncio.run(FetchUsers())
```

#### Connection Pooling

```python
import asyncio
import asyncpg

async def QueryWithPool(Pool: asyncpg.Pool, UserId: int) -> dict:
    """Execute query using connection pool"""
    async with Pool.acquire() as Connection:
        Row = await Connection.fetchrow(
            'SELECT * FROM users WHERE id = $1',
            UserId
        )
        return dict(Row) if Row else None

async def UseConnectionPool():
    """Manage database connection pool"""
    Pool = await asyncpg.create_pool(
        user='user',
        password='password',
        database='mydb',
        host='localhost',
        min_size=10,
        max_size=20
    )
    
    try:
        # Execute multiple queries concurrently
        Results = await asyncio.gather(
            QueryWithPool(Pool, 1),
            QueryWithPool(Pool, 2),
            QueryWithPool(Pool, 3)
        )
        
        for Result in Results:
            print(Result)
    finally:
        await Pool.close()

asyncio.run(UseConnectionPool())
```

## Synchronization Primitives

### Locks

Locks ensure only one coroutine accesses a resource at a time:

```python
import asyncio

class SharedResource:
    """Resource that requires synchronized access"""
    def __init__(self):
        self.Value = 0
        self.Lock = asyncio.Lock()
    
    async def Increment(self, TaskName: str):
        """Safely increment the shared value"""
        async with self.Lock:
            # Critical section
            print(f"{TaskName}: Reading value {self.Value}")
            await asyncio.sleep(0.1)  # Simulate work
            self.Value += 1
            print(f"{TaskName}: Set value to {self.Value}")

async def UseLock():
    """Demonstrate Lock usage"""
    Resource = SharedResource()
    
    # Multiple tasks competing for resource
    await asyncio.gather(
        Resource.Increment("Task-1"),
        Resource.Increment("Task-2"),
        Resource.Increment("Task-3")
    )
    
    print(f"Final value: {Resource.Value}")

asyncio.run(UseLock())
```

### Events

Events allow coroutines to wait for a signal:

```python
import asyncio

async def Waiter(Event: asyncio.Event, Name: str):
    """Wait for event to be set"""
    print(f"{Name}: Waiting for event")
    await Event.wait()
    print(f"{Name}: Event received, proceeding")

async def Setter(Event: asyncio.Event):
    """Set the event after delay"""
    print("Setter: Working...")
    await asyncio.sleep(2)
    print("Setter: Setting event")
    Event.set()

async def UseEvent():
    """Demonstrate Event usage"""
    Event = asyncio.Event()
    
    await asyncio.gather(
        Waiter(Event, "Waiter-1"),
        Waiter(Event, "Waiter-2"),
        Waiter(Event, "Waiter-3"),
        Setter(Event)
    )

asyncio.run(UseEvent())
```

### Semaphores

Semaphores limit concurrent access to a resource:

```python
import asyncio

async def AccessResource(Semaphore: asyncio.Semaphore, 
                        TaskNum: int):
    """Access limited resource"""
    print(f"Task {TaskNum}: Waiting for access")
    
    async with Semaphore:
        print(f"Task {TaskNum}: Accessing resource")
        await asyncio.sleep(1)  # Simulate work
        print(f"Task {TaskNum}: Releasing resource")

async def UseSemaphore():
    """Demonstrate Semaphore usage"""
    # Allow only 2 concurrent accesses
    Semaphore = asyncio.Semaphore(2)
    
    # Create 5 tasks trying to access resource
    Tasks = [
        AccessResource(Semaphore, i)
        for i in range(1, 6)
    ]
    
    await asyncio.gather(*Tasks)

asyncio.run(UseSemaphore())
```

### Conditions

Conditions allow complex synchronization patterns:

```python
import asyncio

class Buffer:
    """Bounded buffer with condition variable"""
    def __init__(self, MaxSize: int):
        self.Items = []
        self.MaxSize = MaxSize
        self.Condition = asyncio.Condition()
    
    async def Put(self, Item: str):
        """Add item to buffer"""
        async with self.Condition:
            # Wait while buffer is full
            while len(self.Items) >= self.MaxSize:
                print(f"Buffer full, waiting to add {Item}")
                await self.Condition.wait()
            
            self.Items.append(Item)
            print(f"Added {Item} (buffer: {len(self.Items)})")
            self.Condition.notify()
    
    async def Get(self) -> str:
        """Remove item from buffer"""
        async with self.Condition:
            # Wait while buffer is empty
            while not self.Items:
                print("Buffer empty, waiting for items")
                await self.Condition.wait()
            
            Item = self.Items.pop(0)
            print(f"Removed {Item} (buffer: {len(self.Items)})")
            self.Condition.notify()
            return Item

async def Producer(Buffer: Buffer, Items: list):
    """Produce items"""
    for Item in Items:
        await Buffer.Put(Item)
        await asyncio.sleep(0.5)

async def Consumer(Buffer: Buffer, Count: int):
    """Consume items"""
    for _ in range(Count):
        Item = await Buffer.Get()
        await asyncio.sleep(1)

async def UseCondition():
    """Demonstrate Condition usage"""
    Buffer = Buffer(MaxSize=3)
    
    await asyncio.gather(
        Producer(Buffer, ["Item1", "Item2", "Item3", "Item4", "Item5"]),
        Consumer(Buffer, 5)
    )

asyncio.run(UseCondition())
```

### Barriers

Barriers synchronize multiple coroutines at a point:

```python
import asyncio

async def Worker(Barrier: asyncio.Barrier, WorkerId: int):
    """Worker that synchronizes at barrier"""
    print(f"Worker {WorkerId}: Starting phase 1")
    await asyncio.sleep(WorkerId * 0.5)  # Different durations
    print(f"Worker {WorkerId}: Finished phase 1")
    
    # Wait for all workers at barrier
    await Barrier.wait()
    
    print(f"Worker {WorkerId}: Starting phase 2")
    await asyncio.sleep(1)
    print(f"Worker {WorkerId}: Finished phase 2")

async def UseBarrier():
    """Demonstrate Barrier usage"""
    # Barrier for 3 workers
    Barrier = asyncio.Barrier(3)
    
    await asyncio.gather(
        Worker(Barrier, 1),
        Worker(Barrier, 2),
        Worker(Barrier, 3)
    )

asyncio.run(UseBarrier())
```

## Best Practices

### Use asyncio.run() for Entry Points

**Always use** `asyncio.run()` as the main entry point:

```python
# ✅ Good
import asyncio

async def Main():
    """Application entry point"""
    await DoWork()

asyncio.run(Main())

# ❌ Avoid manual loop management
Loop = asyncio.get_event_loop()
Loop.run_until_complete(Main())
Loop.close()
```

### Avoid Blocking Operations

**Never block the event loop** with synchronous operations:

```python
import asyncio
import time
import requests  # Synchronous library

# ❌ Avoid blocking calls
async def BadExample():
    """Blocking call stops all coroutines"""
    time.sleep(5)  # Blocks entire event loop!
    Response = requests.get('https://api.example.com')  # Blocks!

# ✅ Use async alternatives
async def GoodExample():
    """Non-blocking operations"""
    await asyncio.sleep(5)  # Allows other coroutines to run
    
    async with aiohttp.ClientSession() as Session:
        async with Session.get('https://api.example.com') as Response:
            return await Response.text()
```

### Run Blocking Code in Executors

When you **must use blocking code**, run it in an executor:

```python
import asyncio
from concurrent.futures import ThreadPoolExecutor
import requests

async def FetchWithRequests(Url: str) -> str:
    """Use synchronous requests library safely"""
    Loop = asyncio.get_event_loop()
    
    # Run blocking code in thread pool
    Response = await Loop.run_in_executor(
        None,  # Use default executor
        requests.get,
        Url
    )
    
    return Response.text

async def CpuBoundTask(Number: int) -> int:
    """Run CPU-intensive task in executor"""
    import math
    
    def Factorial(N: int) -> int:
        """Blocking CPU-bound operation"""
        return math.factorial(N)
    
    Loop = asyncio.get_event_loop()
    return await Loop.run_in_executor(None, Factorial, Number)

async def Main():
    """Mix blocking and async code safely"""
    Results = await asyncio.gather(
        FetchWithRequests('https://httpbin.org/delay/1'),
        CpuBoundTask(100000)
    )
    print(Results)

asyncio.run(Main())
```

### Proper Exception Handling

**Always handle exceptions** in async code:

```python
import asyncio

async def RiskyOperation(OperationId: int):
    """Operation that might fail"""
    await asyncio.sleep(1)
    if OperationId == 2:
        raise ValueError(f"Operation {OperationId} failed")
    return f"Result {OperationId}"

# ❌ Avoid: Silent failures
async def BadExceptionHandling():
    """Exceptions in gather() are raised"""
    try:
        Results = await asyncio.gather(
            RiskyOperation(1),
            RiskyOperation(2),  # This will raise
            RiskyOperation(3)
        )
    except ValueError:
        # Too broad - we don't know which one failed
        pass

# ✅ Good: Handle individually or use return_exceptions
async def GoodExceptionHandling():
    """Explicit exception handling"""
    # Option 1: return_exceptions parameter
    Results = await asyncio.gather(
        RiskyOperation(1),
        RiskyOperation(2),
        RiskyOperation(3),
        return_exceptions=True
    )
    
    for Index, Result in enumerate(Results):
        if isinstance(Result, Exception):
            print(f"Operation {Index + 1} failed: {Result}")
        else:
            print(f"Operation {Index + 1} succeeded: {Result}")
    
    # Option 2: Wrap each operation
    async def SafeOperation(OperationId: int):
        try:
            return await RiskyOperation(OperationId)
        except ValueError as Error:
            print(f"Handled error for {OperationId}: {Error}")
            return None
    
    Results = await asyncio.gather(
        SafeOperation(1),
        SafeOperation(2),
        SafeOperation(3)
    )

asyncio.run(GoodExceptionHandling())
```

### Handle Task Cancellation

**Always handle** `CancelledError` for cleanup:

```python
import asyncio

async def CleanupTask():
    """Task with proper cancellation handling"""
    Resource = None
    try:
        Resource = await AcquireResource()
        await DoWork(Resource)
    except asyncio.CancelledError:
        print("Task cancelled, cleaning up...")
        if Resource:
            await CleanupResource(Resource)
        raise  # Re-raise to propagate cancellation
    finally:
        # Also runs on cancellation
        print("Final cleanup")

async def AcquireResource():
    """Simulate resource acquisition"""
    await asyncio.sleep(0.1)
    return "Resource"

async def CleanupResource(Resource: str):
    """Simulate resource cleanup"""
    await asyncio.sleep(0.1)
    print(f"Cleaned up {Resource}")

async def DoWork(Resource: str):
    """Simulate long-running work"""
    await asyncio.sleep(10)
```

### Use Appropriate Concurrency Primitives

**Choose the right tool** for coordination:

```python
import asyncio

# Use Lock for exclusive access
class Counter:
    def __init__(self):
        self.Value = 0
        self.Lock = asyncio.Lock()
    
    async def Increment(self):
        async with self.Lock:
            self.Value += 1

# Use Semaphore for limiting concurrency
async def RateLimitedFetch(Url: str, Semaphore: asyncio.Semaphore):
    """Limit concurrent requests"""
    async with Semaphore:
        return await FetchUrl(Url)

# Use Event for one-time signals
async def WaitForStartup(Event: asyncio.Event):
    """Wait for application to be ready"""
    await Event.wait()
    await DoWork()

# Use Queue for producer-consumer
async def ProcessingPipeline():
    """Pipeline with multiple stages"""
    Queue = asyncio.Queue(maxsize=10)
    
    async def Producer():
        for Item in range(100):
            await Queue.put(Item)
        await Queue.put(None)  # Sentinel
    
    async def Consumer():
        while True:
            Item = await Queue.get()
            if Item is None:
                break
            await ProcessItem(Item)
    
    await asyncio.gather(Producer(), Consumer())
```

### Name Your Tasks

**Use descriptive names** for debugging:

```python
import asyncio

async def Main():
    """Name tasks for better debugging"""
    # ❌ Anonymous tasks are hard to debug
    Task1 = asyncio.create_task(FetchData(1))
    Task2 = asyncio.create_task(FetchData(2))
    
    # ✅ Named tasks show up in debugging
    Task1 = asyncio.create_task(
        FetchData(1),
        name="FetchUser1"
    )
    Task2 = asyncio.create_task(
        FetchData(2),
        name="FetchUser2"
    )
    
    # View all tasks
    for Task in asyncio.all_tasks():
        print(f"Task: {Task.get_name()}")
    
    await asyncio.gather(Task1, Task2)
```

### Use Context Managers

**Prefer context managers** for resource management:

```python
import asyncio
import aiohttp

# ✅ Good: Automatic cleanup
async def GoodResourceManagement():
    """Resources cleaned up automatically"""
    async with aiohttp.ClientSession() as Session:
        async with Session.get('https://api.example.com') as Response:
            return await Response.text()

# ❌ Avoid: Manual cleanup is error-prone
async def BadResourceManagement():
    """Must remember to clean up"""
    Session = aiohttp.ClientSession()
    Response = await Session.get('https://api.example.com')
    Text = await Response.text()
    await Response.close()
    await Session.close()
    return Text
```

### Structure for Testability

**Design async code** for easy testing:

```python
import asyncio

# ✅ Good: Dependency injection
class DataFetcher:
    """Testable data fetcher"""
    def __init__(self, HttpClient):
        self.Client = HttpClient
    
    async def FetchUser(self, UserId: int) -> dict:
        """Fetch user data"""
        Response = await self.Client.get(f'/users/{UserId}')
        return await Response.json()

# Can inject mock client for testing
async def TestFetchUser():
    """Test with mock client"""
    MockClient = MockHttpClient()
    Fetcher = DataFetcher(MockClient)
    User = await Fetcher.FetchUser(1)
    assert User['id'] == 1

# ❌ Avoid: Hard-coded dependencies
async def FetchUserBad(UserId: int) -> dict:
    """Hard to test"""
    async with aiohttp.ClientSession() as Session:
        Response = await Session.get(f'https://api.example.com/users/{UserId}')
        return await Response.json()
```

### Configure Logging

**Enable asyncio logging** for debugging:

```python
import asyncio
import logging

# Enable asyncio debug mode
logging.basicConfig(level=logging.DEBUG)
asyncio.get_event_loop().set_debug(True)

# Or via environment variable
# PYTHONASYNCIODEBUG=1 python script.py

async def Main():
    """Debug mode shows warnings"""
    # Warns if coroutine takes too long
    await asyncio.sleep(1)

asyncio.run(Main())
```

## Common Pitfalls

### Forgetting to Await Coroutines

**Symptom**: Coroutine object returned instead of result, runtime warning about unawaited coroutine.

```python
import asyncio

async def FetchData() -> str:
    """Async function"""
    await asyncio.sleep(1)
    return "Data"

# ❌ Wrong: Returns coroutine object
async def BadUsage():
    Result = FetchData()  # Missing await!
    print(Result)  # <coroutine object FetchData at 0x...>

# ✅ Correct: Await the coroutine
async def GoodUsage():
    Result = await FetchData()
    print(Result)  # "Data"

asyncio.run(GoodUsage())
```

### Blocking the Event Loop

**Symptom**: All coroutines freeze when one does blocking I/O or CPU work.

```python
import asyncio
import time
import requests

# ❌ Wrong: Blocking operations
async def BlockingExample():
    """These block the entire event loop"""
    time.sleep(5)  # Blocks everything!
    Response = requests.get('https://api.example.com')  # Blocks!
    
    with open('large_file.txt') as File:  # Blocks on I/O!
        Content = File.read()

# ✅ Correct: Use async alternatives
async def NonBlockingExample():
    """Proper async operations"""
    await asyncio.sleep(5)  # Non-blocking
    
    async with aiohttp.ClientSession() as Session:
        async with Session.get('https://api.example.com') as Response:
            Data = await Response.text()
    
    async with aiofiles.open('large_file.txt') as File:
        Content = await File.read()

# ✅ Or use executors for blocking code
async def ExecutorExample():
    """Run blocking code in thread pool"""
    Loop = asyncio.get_event_loop()
    
    # Run in executor
    await Loop.run_in_executor(None, time.sleep, 5)
    Response = await Loop.run_in_executor(None, requests.get, 'https://api.example.com')
```

### Not Handling Task Cancellation

**Symptom**: Resources not cleaned up, warnings about tasks destroyed while pending.

```python
import asyncio

# ❌ Wrong: No cancellation handling
async def BadTask():
    """Resource leak on cancellation"""
    Connection = await OpenConnection()
    await asyncio.sleep(100)
    await Connection.close()  # Never reached if cancelled!

# ✅ Correct: Handle CancelledError
async def GoodTask():
    """Proper cleanup on cancellation"""
    Connection = await OpenConnection()
    try:
        await asyncio.sleep(100)
    except asyncio.CancelledError:
        await Connection.close()  # Cleanup happens
        raise  # Re-raise to propagate cancellation
    finally:
        # Alternative: cleanup in finally
        pass

async def OpenConnection():
    """Simulate connection"""
    return "Connection"
```

### Creating Tasks Without Keeping References

**Symptom**: Tasks garbage collected before completion, lost exceptions.

```python
import asyncio

# ❌ Wrong: Task reference lost
async def BadTaskCreation():
    """Task may be garbage collected"""
    asyncio.create_task(BackgroundWork())  # No reference!
    await asyncio.sleep(1)

# ✅ Correct: Keep task reference
async def GoodTaskCreation():
    """Proper task management"""
    Task = asyncio.create_task(BackgroundWork())
    try:
        await asyncio.sleep(1)
    finally:
        Task.cancel()
        try:
            await Task
        except asyncio.CancelledError:
            pass

# ✅ Better: Use task groups (Python 3.11+)
async def BestTaskCreation():
    """Automatic task lifecycle management"""
    async with asyncio.TaskGroup() as Group:
        Task = Group.create_task(BackgroundWork())
    # All tasks awaited automatically

async def BackgroundWork():
    """Background operation"""
    await asyncio.sleep(5)
```

### Modifying Shared State Without Locks

**Symptom**: Race conditions, incorrect final values, non-deterministic behavior.

```python
import asyncio

# ❌ Wrong: Race condition
class UnsafeCounter:
    """Not thread-safe for async"""
    def __init__(self):
        self.Count = 0
    
    async def Increment(self):
        """Race condition here"""
        CurrentValue = self.Count
        await asyncio.sleep(0)  # Context switch point!
        self.Count = CurrentValue + 1

async def BadConcurrency():
    """Unpredictable results"""
    Counter = UnsafeCounter()
    await asyncio.gather(
        Counter.Increment(),
        Counter.Increment(),
        Counter.Increment()
    )
    print(Counter.Count)  # May be 1, 2, or 3!

# ✅ Correct: Use Lock
class SafeCounter:
    """Protected with Lock"""
    def __init__(self):
        self.Count = 0
        self.Lock = asyncio.Lock()
    
    async def Increment(self):
        """Thread-safe increment"""
        async with self.Lock:
            CurrentValue = self.Count
            await asyncio.sleep(0)
            self.Count = CurrentValue + 1

async def GoodConcurrency():
    """Predictable results"""
    Counter = SafeCounter()
    await asyncio.gather(
        Counter.Increment(),
        Counter.Increment(),
        Counter.Increment()
    )
    print(Counter.Count)  # Always 3

asyncio.run(GoodConcurrency())
```

### Not Setting Timeouts

**Symptom**: Program hangs indefinitely on slow/failed operations.

```python
import asyncio

# ❌ Wrong: No timeout
async def BadRequest():
    """May hang forever"""
    Response = await FetchData()  # Waits forever if server doesn't respond

# ✅ Correct: Always set timeouts
async def GoodRequest():
    """Fails fast on timeout"""
    try:
        Response = await asyncio.wait_for(FetchData(), timeout=5.0)
    except asyncio.TimeoutError:
        print("Request timed out")
        return None

async def FetchData():
    """Simulate slow request"""
    await asyncio.sleep(10)
    return "Data"
```

### Misusing asyncio.gather()

**Symptom**: All operations fail if one fails, or exceptions silently ignored.

```python
import asyncio

async def FailingOperation():
    """This will fail"""
    await asyncio.sleep(1)
    raise ValueError("Failed!")

async def SuccessfulOperation():
    """This succeeds"""
    await asyncio.sleep(1)
    return "Success"

# ❌ Wrong: One failure stops everything
async def BadGather():
    """First exception cancels others"""
    try:
        Results = await asyncio.gather(
            SuccessfulOperation(),
            FailingOperation(),
            SuccessfulOperation()
        )
    except ValueError:
        print("Lost all results!")

# ✅ Correct: Handle exceptions per operation
async def GoodGather():
    """Collect all results and errors"""
    Results = await asyncio.gather(
        SuccessfulOperation(),
        FailingOperation(),
        SuccessfulOperation(),
        return_exceptions=True
    )
    
    for Index, Result in enumerate(Results):
        if isinstance(Result, Exception):
            print(f"Operation {Index} failed: {Result}")
        else:
            print(f"Operation {Index} succeeded: {Result}")

asyncio.run(GoodGather())
```

### Reusing Event Loop

**Symptom**: RuntimeError about event loop already running or closed.

```python
import asyncio

# ❌ Wrong: Trying to reuse loop
def BadLoopUsage():
    """Don't manually manage loops"""
    Loop = asyncio.get_event_loop()
    Loop.run_until_complete(DoWork())
    Loop.run_until_complete(DoMoreWork())  # May fail!
    Loop.close()

# ✅ Correct: Use asyncio.run()
def GoodLoopUsage():
    """Let asyncio manage the loop"""
    asyncio.run(Main())

async def Main():
    """Single entry point"""
    await DoWork()
    await DoMoreWork()

async def DoWork():
    await asyncio.sleep(1)

async def DoMoreWork():
    await asyncio.sleep(1)
```

## Resources

### Official Documentation

- [asyncio Documentation](https://docs.python.org/3/library/asyncio.html) - Complete reference for asyncio library
- [asyncio Task Guide](https://docs.python.org/3/library/asyncio-task.html) - Working with coroutines and tasks
- [asyncio Streams](https://docs.python.org/3/library/asyncio-stream.html) - High-level async I/O
- [asyncio Synchronization](https://docs.python.org/3/library/asyncio-sync.html) - Locks, events, semaphores
- [asyncio Queues](https://docs.python.org/3/library/asyncio-queue.html) - Async queue implementations

### Tutorials and Guides

- [Real Python: Async IO in Python](https://realpython.com/async-io-python/) - Comprehensive tutorial
- [Python asyncio: The Complete Guide](https://superfastpython.com/python-asyncio/) - Detailed examples
- [asyncio Cheat Sheet](https://www.pythonsheets.com/notes/python-asyncio.html) - Quick reference
- [Edge DB: asyncio Tutorial](https://www.edgedb.com/blog/we-can-do-better-than-sql) - Advanced patterns

### Libraries and Tools

#### HTTP Clients

- [aiohttp](https://docs.aiohttp.org/) - Async HTTP client/server framework
- [httpx](https://www.python-httpx.org/) - Async HTTP client with sync fallback

#### Database

- [asyncpg](https://github.com/MagicStack/asyncpg) - Fast PostgreSQL driver
- [motor](https://motor.readthedocs.io/) - Async MongoDB driver
- [aiomysql](https://github.com/aio-libs/aiomysql) - MySQL async driver
- [aiosqlite](https://github.com/omnilib/aiosqlite) - SQLite async wrapper

#### File I/O

- [aiofiles](https://github.com/Tinche/aiofiles) - Async file operations

#### Testing

- [pytest-asyncio](https://github.com/pytest-dev/pytest-asyncio) - pytest support for asyncio
- [aiounittest](https://github.com/kwarunek/aiounittest) - Unittest for async code

#### Utilities

- [trio](https://trio.readthedocs.io/) - Alternative async framework
- [anyio](https://anyio.readthedocs.io/) - Compatibility layer for asyncio/trio
- [aiostream](https://github.com/vxgmichel/aiostream) - Async stream operators

### Books

- **"Using Asyncio in Python"** by Caleb Hattingh - O'Reilly
- **"Python Concurrency with asyncio"** by Matthew Fowler - Manning
- **"Fluent Python, 2nd Edition"** by Luciano Ramalho - O'Reilly (Chapter 21)

### Videos and Talks

- [Miguel Grinberg: Asynchronous Python for the Complete Beginner](https://www.youtube.com/watch?v=iG6fr81xHKA) - PyCon 2017
- [Yury Selivanov: asyncio in Python 3.7 and beyond](https://www.youtube.com/watch?v=ReXxO_azV-w) - PyCon 2018
- [Lynn Root: Advanced asyncio](https://www.youtube.com/watch?v=sW76-pRkZk8) - PyCon 2019

### Community

- [Python Discord - async channel](https://discord.gg/python)
- [Stack Overflow - asyncio tag](https://stackoverflow.com/questions/tagged/python-asyncio)
- [Reddit - r/learnpython](https://www.reddit.com/r/learnpython/)

## Examples

### Web Scraper with Rate Limiting

```python
import asyncio
import aiohttp
from typing import List

async def FetchPage(Session: aiohttp.ClientSession, 
                    Url: str,
                    Semaphore: asyncio.Semaphore) -> dict:
    """Fetch single page with rate limiting"""
    async with Semaphore:
        try:
            async with Session.get(Url, timeout=aiohttp.ClientTimeout(total=10)) as Response:
                Content = await Response.text()
                return {
                    "url": Url,
                    "status": Response.status,
                    "length": len(Content),
                    "success": True
                }
        except Exception as Error:
            return {
                "url": Url,
                "error": str(Error),
                "success": False
            }

async def ScrapeWebsites(Urls: List[str], MaxConcurrent: int = 5):
    """Scrape multiple websites with rate limiting"""
    Semaphore = asyncio.Semaphore(MaxConcurrent)
    
    async with aiohttp.ClientSession() as Session:
        Tasks = [FetchPage(Session, Url, Semaphore) for Url in Urls]
        Results = await asyncio.gather(*Tasks)
        
        # Process results
        Successful = [R for R in Results if R.get('success')]
        Failed = [R for R in Results if not R.get('success')]
        
        print(f"Successful: {len(Successful)}, Failed: {len(Failed)}")
        
        for Result in Results:
            if Result.get('success'):
                print(f"✓ {Result['url']}: {Result['status']} ({Result['length']} bytes)")
            else:
                print(f"✗ {Result['url']}: {Result['error']}")
        
        return Results

# Usage
Urls = [
    "https://example.com",
    "https://python.org",
    "https://github.com",
    "https://stackoverflow.com"
]

asyncio.run(ScrapeWebsites(Urls, MaxConcurrent=2))
```

### Background Task Manager

```python
import asyncio
from typing import Callable, Any
from datetime import datetime

class TaskManager:
    """Manage background tasks with graceful shutdown"""
    
    def __init__(self):
        self.Tasks = set()
        self.Running = False
    
    async def Start(self):
        """Start the task manager"""
        self.Running = True
        print(f"[{datetime.now()}] TaskManager started")
    
    async def Stop(self):
        """Gracefully stop all tasks"""
        print(f"[{datetime.now()}] Stopping TaskManager...")
        self.Running = False
        
        # Cancel all tasks
        for Task in self.Tasks:
            Task.cancel()
        
        # Wait for cancellation
        await asyncio.gather(*self.Tasks, return_exceptions=True)
        print(f"[{datetime.now()}] All tasks stopped")
    
    def AddTask(self, Coroutine: Callable, Name: str) -> asyncio.Task:
        """Add a background task"""
        Task = asyncio.create_task(Coroutine(), name=Name)
        self.Tasks.add(Task)
        Task.add_done_callback(self.Tasks.discard)
        return Task
    
    async def PeriodicTask(self, Interval: float, Func: Callable, Name: str):
        """Run function periodically"""
        print(f"[{datetime.now()}] Starting periodic task: {Name}")
        try:
            while self.Running:
                await Func()
                await asyncio.sleep(Interval)
        except asyncio.CancelledError:
            print(f"[{datetime.now()}] {Name} cancelled")
        finally:
            print(f"[{datetime.now()}] {Name} stopped")

async def DataCollector():
    """Example: Collect data periodically"""
    print(f"[{datetime.now()}] Collecting data...")
    await asyncio.sleep(0.5)

async def HealthCheck():
    """Example: Perform health check"""
    print(f"[{datetime.now()}] Health check...")
    await asyncio.sleep(0.3)

async def Main():
    """Run background tasks with graceful shutdown"""
    Manager = TaskManager()
    await Manager.Start()
    
    # Add periodic tasks
    Manager.AddTask(
        lambda: Manager.PeriodicTask(2.0, DataCollector, "DataCollector"),
        "DataCollector"
    )
    Manager.AddTask(
        lambda: Manager.PeriodicTask(3.0, HealthCheck, "HealthCheck"),
        "HealthCheck"
    )
    
    # Run for a while
    try:
        await asyncio.sleep(10)
    except KeyboardInterrupt:
        print("\nReceived interrupt signal")
    finally:
        await Manager.Stop()

asyncio.run(Main())
```

### API Client with Retry Logic

```python
import asyncio
import aiohttp
from typing import Optional, Any
import logging

logging.basicConfig(level=logging.INFO)
Logger = logging.getLogger(__name__)

class ApiClient:
    """API client with automatic retry and exponential backoff"""
    
    def __init__(self, BaseUrl: str, MaxRetries: int = 3):
        self.BaseUrl = BaseUrl
        self.MaxRetries = MaxRetries
        self.Session: Optional[aiohttp.ClientSession] = None
    
    async def __aenter__(self):
        """Context manager entry"""
        self.Session = aiohttp.ClientSession()
        return self
    
    async def __aexit__(self, ExcType, ExcVal, ExcTb):
        """Context manager exit"""
        if self.Session:
            await self.Session.close()
    
    async def Request(self, 
                     Method: str, 
                     Endpoint: str, 
                     **Kwargs: Any) -> Optional[dict]:
        """Make HTTP request with retry logic"""
        Url = f"{self.BaseUrl}{Endpoint}"
        
        for Attempt in range(self.MaxRetries):
            try:
                Timeout = aiohttp.ClientTimeout(total=10)
                async with self.Session.request(
                    Method,
                    Url,
                    timeout=Timeout,
                    **Kwargs
                ) as Response:
                    Response.raise_for_status()
                    return await Response.json()
            
            except (aiohttp.ClientError, asyncio.TimeoutError) as Error:
                Logger.warning(
                    f"Attempt {Attempt + 1}/{self.MaxRetries} failed: {Error}"
                )
                
                if Attempt < self.MaxRetries - 1:
                    # Exponential backoff
                    WaitTime = 2 ** Attempt
                    Logger.info(f"Retrying in {WaitTime}s...")
                    await asyncio.sleep(WaitTime)
                else:
                    Logger.error(f"All retry attempts failed for {Url}")
                    raise
        
        return None
    
    async def Get(self, Endpoint: str, **Kwargs: Any) -> Optional[dict]:
        """GET request"""
        return await self.Request("GET", Endpoint, **Kwargs)
    
    async def Post(self, Endpoint: str, **Kwargs: Any) -> Optional[dict]:
        """POST request"""
        return await self.Request("POST", Endpoint, **Kwargs)

async def Main():
    """Example usage"""
    async with ApiClient("https://jsonplaceholder.typicode.com") as Client:
        # Fetch user
        User = await Client.Get("/users/1")
        print(f"User: {User['name']}")
        
        # Fetch posts
        Posts = await Client.Get("/posts", params={"userId": 1})
        print(f"Posts: {len(Posts)}")
        
        # Create post
        NewPost = await Client.Post(
            "/posts",
            json={
                "title": "Test Post",
                "body": "Content",
                "userId": 1
            }
        )
        print(f"Created post: {NewPost['id']}")

asyncio.run(Main())
```

### Real-time Data Pipeline

```python
import asyncio
import random
from typing import AsyncGenerator

async def DataSource(SourceId: int) -> AsyncGenerator[dict, None]:
    """Simulate streaming data source"""
    while True:
        await asyncio.sleep(random.uniform(0.5, 2.0))
        yield {
            "source": SourceId,
            "value": random.randint(1, 100),
            "timestamp": asyncio.get_event_loop().time()
        }

async def ProcessData(Data: dict) -> dict:
    """Process incoming data"""
    await asyncio.sleep(0.1)  # Simulate processing
    return {
        **Data,
        "processed": True,
        "squared": Data["value"] ** 2
    }

async def SaveToDatabase(Data: dict):
    """Simulate database save"""
    await asyncio.sleep(0.2)
    print(f"Saved: Source {Data['source']}, Value {Data['value']}, "
          f"Squared {Data['squared']}")

async def DataPipeline(SourceCount: int, Duration: float):
    """Real-time data processing pipeline"""
    Queue = asyncio.Queue(maxsize=20)
    
    async def Producer(SourceId: int):
        """Produce data from source"""
        async for Data in DataSource(SourceId):
            await Queue.put(Data)
    
    async def Consumer():
        """Consume and process data"""
        while True:
            Data = await Queue.get()
            try:
                Processed = await ProcessData(Data)
                await SaveToDatabase(Processed)
            except Exception as Error:
                print(f"Error processing data: {Error}")
            finally:
                Queue.task_done()
    
    # Start producers and consumers
    Producers = [
        asyncio.create_task(Producer(i), name=f"Producer-{i}")
        for i in range(SourceCount)
    ]
    
    Consumers = [
        asyncio.create_task(Consumer(), name=f"Consumer-{i}")
        for i in range(3)
    ]
    
    # Run for duration
    await asyncio.sleep(Duration)
    
    # Cleanup
    for Producer in Producers:
        Producer.cancel()
    
    await Queue.join()  # Wait for queue to empty
    
    for Consumer in Consumers:
        Consumer.cancel()
    
    await asyncio.gather(*Producers, *Consumers, return_exceptions=True)
    print(f"\nPipeline completed. Processed {Queue._qsize} items.")

asyncio.run(DataPipeline(SourceCount=3, Duration=10.0))
```
