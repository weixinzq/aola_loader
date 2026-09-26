package mmo.petpackage.controller.skin.styles
{
   import flash.display.DisplayObject;
   import flash.geom.Point;
   import mmo.interfaces.IDispose;
   import mmo.petpackage.controller.skin.controller.IMotion;
   import mmo.petpackage.controller.skin.controller.MotionFactory;
   
   public class Style implements IDispose
   {
      
      private var _target:DisplayObject;
      
      private var _classify:int;
      
      private var _styleType:int;
      
      private var _motion:IMotion;
      
      private var _disappearPos:Point;
      
      private var _classifyArr:Array = null;
      
      public function Style(param1:DisplayObject, param2:int, param3:int, param4:Point = null, param5:Array = null)
      {
         super();
         this._target = param1;
         this._classify = param2;
         this._styleType = param3;
         this._disappearPos = param4;
         this._classifyArr = param5;
         this._motion = MotionFactory.creat(param1,param3,param4);
      }
      
      public function get classify() : int
      {
         return this._classify;
      }
      
      public function disappear() : void
      {
         this._motion.disappear();
      }
      
      public function appear() : void
      {
         this._motion.appear();
      }
      
      public function disappearImmediately() : void
      {
         this._motion.disappearImmediately();
      }
      
      public function dispose() : void
      {
         this._target = null;
         this._motion.dispose();
         this._motion = null;
      }
      
      public function get classifyArr() : Array
      {
         return this._classifyArr;
      }
      
      public function set classifyArr(param1:Array) : void
      {
         this._classifyArr = param1;
      }
   }
}

