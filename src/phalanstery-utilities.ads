-- Copyright 2016 Hadrien Grasland
--
-- This file is part of Phalanstery.
--
-- Phalanstery is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- Phalanstery is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with Phalanstery.  If not, see <http://www.gnu.org/licenses/>.

package Phalanstery.Utilities with Pure is

   -- This package groups together a set of simple components that haven't really found their place anywhere else:
   --
   --    - Utilities.Atomic_Counters abstracts away the functionality of GNAT's System.Atomic_Counters.
   --    - Utilities.Debug provides some debugging tools, particularly related to output.
   --    - Utilities.Exceptions provides some additional exception handling functionality on top of Ada.Exceptions.
   --    - Utilities.Group_Waits provides a way for one task to wait for N others without blocking them.
   --    - Utilities.References provides reference counting facilities, which are used to address the scoping
   --                           complications that arise when objects can asynchronously go out of scope.
   --    - Utilities.Signals provides a way for one task to asynchronously trigger work in N other tasks.
   --    - Utilities.Testing provides unit testing facilities.

end Phalanstery.Utilities;
