package mmo.petpackage.controller.skin
{
   import flash.display.DisplayObject;
   import flash.geom.Point;
   import mmo.interfaces.IDispose;
   import mmo.petpackage.controller.skin.styles.Style;
   
   public class PackageSkinManager implements IDispose
   {
      
      private static var _instance:PackageSkinManager;
      
      private var _objs:Vector.<Style> = new Vector.<Style>();
      
      private var _classify:int = 0;
      
      private var _isShowingLegendary:Boolean = false;
      
      public function PackageSkinManager()
      {
         super();
      }
      
      public static function get instance() : PackageSkinManager
      {
         if(_instance == null)
         {
            _instance = new PackageSkinManager();
         }
         return _instance;
      }
      
      public function get isShowingLegendary() : Boolean
      {
         return this._isShowingLegendary;
      }
      
      public function joinNormals(param1:DisplayObject, param2:int, param3:int, param4:Point, param5:Array = null) : void
      {
         if(param1 == null)
         {
            return;
         }
         this._objs.push(new Style(param1,param2,param3,param4,param5));
      }
      
      public function joinSimple(param1:DisplayObject, param2:int, param3:int, param4:Array = null) : void
      {
         if(param1 == null)
         {
            return;
         }
         if(param4 != null)
         {
            this._objs.push(new Style(param1,param2,param3,null,param4));
         }
         else
         {
            this._objs.push(new Style(param1,param2,param3));
         }
      }
      
      public function joinMultiTargets(param1:Array, param2:int, param3:int, param4:Array = null) : void
      {
         var _loc5_:DisplayObject = null;
         for each(_loc5_ in param1)
         {
            if(param4 != null)
            {
               this.joinSimple(_loc5_,param2,param3,param4);
            }
            else
            {
               this.joinSimple(_loc5_,param2,param3);
            }
         }
      }
      
      public function init() : void
      {
         var _loc1_:Style = null;
         for each(_loc1_ in this._objs)
         {
            if(!(this.classify == _loc1_.classify || _loc1_.classifyArr != null && _loc1_.classifyArr.indexOf(this.classify) != -1))
            {
               _loc1_.disappearImmediately();
            }
         }
      }
      
      public function get classify() : int
      {
         return this._classify;
      }
      
      public function changeClassify(param1:int) : void
      {
         var _loc2_:Style = null;
         for each(_loc2_ in this._objs)
         {
            if(param1 == _loc2_.classify || _loc2_.classifyArr != null && _loc2_.classifyArr.indexOf(param1) != -1)
            {
               _loc2_.appear();
            }
            else
            {
               _loc2_.disappear();
            }
         }
         this._classify = param1;
      }
      
      public function dispose() : void
      {
         _instance = null;
      }
   }
}

