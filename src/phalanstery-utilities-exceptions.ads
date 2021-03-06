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

with Ada.Exceptions;

package Phalanstery.Utilities.Exceptions is

   -- Spawn an occurence of any exception
   procedure Make_Occurrence (What  : Ada.Exceptions.Exception_Id;
                              Where : out Ada.Exceptions.Exception_Occurrence);

   -- Tell whether we are dealing with an occurence of a specific exception
   function Is_Occurrence_Of (Who  : Ada.Exceptions.Exception_Occurrence;
                              What : Ada.Exceptions.Exception_Id) return Boolean;

   -- Tell whether we are dealing with a null exception occurence
   function Is_Null_Occurrence (Who : Ada.Exceptions.Exception_Occurrence) return Boolean;

end Phalanstery.Utilities.Exceptions;
