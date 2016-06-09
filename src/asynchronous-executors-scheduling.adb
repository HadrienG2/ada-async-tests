with Ada.Containers;
with Ada.Exceptions;
with Asynchronous.Events.Composition.Shortcuts;
with Asynchronous.Events.Interfaces;
with Asynchronous.Events.Servers;
with Asynchronous.Tasks;
with Asynchronous.Tasks.Trivial;
with Asynchronous.Utilities.Exceptions;
with Asynchronous.Utilities.Testing;
pragma Elaborate_All (Asynchronous.Utilities.Exceptions,
                      Asynchronous.Utilities.Testing);

package body Asynchronous.Executors.Scheduling is

   use all type Events.Interfaces.Event_Status;
   subtype Finished_Event_Status is Events.Interfaces.Finished_Event_Status;

   Wait_List_Error_Occurence : Ada.Exceptions.Exception_Occurrence;

   procedure Schedule_Ready_Task (Who          : Task_Instance_Reference;
                                  According_To : Finished_Event_Status;
                                  On           : Task_Queue_Reference) is
   begin
      case According_To is
         when Done =>
            On.Set.Ready.Enqueue (Who);
         when Canceled =>
            Who.Set.Completion_Event.Cancel;
         when Error =>
            Who.Set.Completion_Event.Mark_Error (Wait_List_Error_Occurence);
      end case;
   end Schedule_Ready_Task;

   type Scheduled_Task is new Events.Interfaces.Event_Listener_Reference with
      record
         Instance : Task_Instance_Reference;
         Target_Queue : Task_Queue_Reference;
      end record;

   overriding procedure Notify_Event_Status_Change (Where : in out Scheduled_Task;
                                                    What  : Finished_Event_Status) is
   begin
      Schedule_Ready_Task (Who          => Where.Instance,
                           According_To => What,
                           On           => Where.Target_Queue);
      Where.Target_Queue.Set.Pending.Remove_Task;
   end Notify_Event_Status_Change;

   procedure Schedule_Task (Who   : Task_Instance_Reference;
                            After : Interfaces.Event_Wait_List;
                            On    : Task_Queue_Reference) is
      Input_Event : Interfaces.Event_Client := Events.Composition.Shortcuts.When_All (After);
   begin
      case Input_Event.Status is
         when Finished_Event_Status =>
            Schedule_Ready_Task (Who          => Who,
                                 According_To => Input_Event.Status,
                                 On           => On);
         when Pending =>
            On.Set.Pending.Add_Task;
            declare
               Scheduled : Scheduled_Task := (Instance => Who, Target_Queue => On);
            begin
               Input_Event.Add_Listener (Scheduled);
            end;
      end case;
   end Schedule_Task;


   -- The remainder of this package is dedicated to unit tests
   procedure Run_Tests is

      use Utilities.Testing;
      use type Ada.Containers.Count_Type;
      use type Task_Instance_Reference;

      T : Tasks.Trivial.Null_Task;
      Queue : constant Task_Queue_Reference := Task_Queues.References.Make_Task_Queue;

      procedure Test_Finished_Wait_List is
         Instance : constant Task_Instance_Reference := Task_Instances.References.Make_Task_Instance (T);
         Empty_List : Interfaces.Event_Wait_List (2 .. 1);
         New_Instance : Task_Instance_Reference;
      begin

         Schedule_Task (Who   => Instance,
                        After => Empty_List,
                        On    => Queue);
         Assert_Truth (Check   => (Queue.Get.Ready.Current_Use = 1),
                       Message => "If the event wait list is ready, tasks should be enqueued immediately");
         Assert_Truth (Check   => Queue.Get.Pending.No_Pending_Task,
                       Message => "Ready tasks should not be marked as pending");

         Queue.Set.Ready.Dequeue (New_Instance);
         Assert_Truth (Check   => (New_Instance = Instance),
                       Message => "Scheduling a ready task should enqueue the right task instance");

      end Test_Finished_Wait_List;

      procedure Test_Canceled_Wait_List is
         Instance : constant Task_Instance_Reference := Task_Instances.References.Make_Task_Instance (T);
         Client : Interfaces.Event_Client := Events.Servers.Make_Event.Make_Client;
      begin
         Client.Cancel;
         Schedule_Task (Who   => Instance,
                        After => (1 => Client),
                        On    => Queue);
         Assert_Truth (Check   => (Queue.Get.Ready.Current_Use = 0),
                       Message => "Tasks with canceled input events should not be enqueued in the task queue");
         Assert_Truth (Check   => Queue.Get.Pending.No_Pending_Task,
                       Message => "Canceled tasks should not be marked as pending");
         Assert_Truth (Check   => Instance.Get.Completion_Event.Is_Canceled,
                       Message => "Tasks with canceled input events should be marked canceled");
      end Test_Canceled_Wait_List;

      procedure Test_Erronerous_Wait_List is
         Custom_Error : exception;
         Custom_Error_Occurence : Ada.Exceptions.Exception_Occurrence;
         Instance : constant Task_Instance_Reference := Task_Instances.References.Make_Task_Instance (T);
         Server : Events.Servers.Server := Events.Servers.Make_Event;
         Client : constant Interfaces.Event_Client := Server.Make_Client;
         Instance_Client : constant Interfaces.Event_Client := Instance.Get.Completion_Event.Make_Client;
      begin

         Utilities.Exceptions.Make_Occurrence (What  => Custom_Error'Identity,
                                               Where => Custom_Error_Occurence);
         Server.Mark_Error (Custom_Error_Occurence);
         Schedule_Task (Who   => Instance,
                        After => (1 => Client),
                        On    => Queue);
         Assert_Truth (Check   => (Queue.Get.Ready.Current_Use = 0),
                       Message => "Tasks with erronerous input events should not be enqueued in the task queue");
         Assert_Truth (Check   => Queue.Get.Pending.No_Pending_Task,
                       Message => "Erronerous tasks should not be marked as pending");
         Assert_Truth (Check   => (Instance_Client.Status = Error),
                       Message => "Tasks with erronerous input events should be marked erronerous");

         declare
            Test_Error : Ada.Exceptions.Exception_Occurrence;
         begin
            Instance_Client.Get_Error (Test_Error);
            Assert_Truth (Check   => Utilities.Exceptions.Is_Occurrence_Of (
                                        Who  => Test_Error,
                                        What => Interfaces.Error_In_Wait_List'Identity
                                     ),
                          Message => "Task with erronerous input events should be marked with the right error");
         end;

      end Test_Erronerous_Wait_List;

      procedure Test_Pending_Wait_List is
         Instance : Task_Instance_Reference := Task_Instances.References.Make_Task_Instance (T);
         Server : Events.Servers.Server := Events.Servers.Make_Event;
         Client : constant Interfaces.Event_Client := Server.Make_Client;
         Instance_Client : constant Interfaces.Event_Client := Instance.Get.Completion_Event.Make_Client;
      begin

         Schedule_Task (Who   => Instance,
                        After => (1 => Client),
                        On    => Queue);
         Assert_Truth (Check   => (Queue.Get.Ready.Current_Use = 0),
                       Message => "Pending tasks should not be put on the ready queue");
         Assert_Truth (Check   => (not Queue.Get.Pending.No_Pending_Task),
                       Message => "Pending tasks should be accounted as appropriate");

         Server.Mark_Done;
         Assert_Truth (Check   => (Queue.Get.Ready.Current_Use = 1),
                       Message => "Tasks should go to the ready queue when ready");
         Assert_Truth (Check   => Queue.Get.Pending.No_Pending_Task,
                       Message => "Tasks should not remain on the pending queue after becoming ready.");
         Assert_Truth (Check   => (Instance_Client.Status = Pending),
                       Message => "Pending tasks should still be pending after being enqueued");

         Queue.Set.Ready.Dequeue (Instance);

      end Test_Pending_Wait_List;

   begin
      Test_Finished_Wait_List;
      Test_Canceled_Wait_List;
      Test_Erronerous_Wait_List;
      Test_Pending_Wait_List;
   end Run_Tests;

begin

   -- Save an occurence of Error_In_Wait_List, to be propagated as needed
   Utilities.Exceptions.Make_Occurrence (What  => Interfaces.Error_In_Wait_List'Identity,
                                         Where => Wait_List_Error_Occurence);

   -- Conditionally run the unit tests on startup
   Utilities.Testing.Startup_Test (Run_Tests'Access);

end Asynchronous.Executors.Scheduling;
