package mmo.petpackage.controller.skin.controller
{
   import mmo.interfaces.IDispose;
   
   public interface IMotion extends IDispose
   {
      
      function appear() : void;
      
      function disappear() : void;
      
      function disappearImmediately() : void;
   }
}

