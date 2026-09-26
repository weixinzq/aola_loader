package mmo.petpackage.panel.inclusion.interfaces
{
   import mmo.interfaces.IDispose;
   
   public interface IPetView extends IDispose
   {
      
      function updateUI() : void;
      
      function reset() : void;
      
      function removeUI() : void;
   }
}

