package mmo.petfightnew.common.bossmovie
{
   import flash.display.MovieClip;
   import mmo.interfaces.pet.fight.IPetFightConfig;
   import mmo.loader.common.datastructures.ResourceObject;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.ServicePool;
   
   public class BossMovieConfig
   {
      
      private static var config:Object = {};
      
      public static const OPENING:int = 100;
      
      public static const HALF_HP:int = 50;
      
      public static const QUARTER_HP:int = 25;
      
      public static const DIE:int = 101;
      
      public static const REVIVE:int = 0;
      
      public static const MY_QUARTER_HP:int = -25;
      
      private static var _inited:Boolean = false;
      
      public function BossMovieConfig()
      {
         super();
      }
      
      private static function init() : void
      {
         if(_inited)
         {
            return;
         }
         _inited = true;
         var _loc1_:IPetFightConfig = ServicePool.instance.getService("PetFightService");
         config = _loc1_.BossMovieConig;
      }
      
      public static function getConfig(param1:int) : Array
      {
         init();
         return config[param1];
      }
      
      public static function getBossMcRes(param1:int, param2:int = 100) : ResourceObject
      {
         var _loc5_:Object = null;
         var _loc6_:ResourceObject = null;
         init();
         if(config[param1] == null)
         {
            return null;
         }
         var _loc3_:String = config[param1][0].file;
         var _loc4_:String = "";
         for each(_loc5_ in config[param1])
         {
            if(_loc5_.type == param2)
            {
               _loc4_ = _loc5_.mc;
            }
         }
         _loc6_ = null;
         if(_loc4_.length > 0)
         {
            _loc6_ = new ResourceObject(_loc3_,_loc4_);
         }
         return _loc6_;
      }
      
      public static function checkBossMc(param1:int, param2:int = 100) : MovieClip
      {
         var _loc3_:Object = null;
         var _loc4_:Class = null;
         init();
         if(config[param1] == null)
         {
            return null;
         }
         for each(_loc3_ in config[param1])
         {
            if(_loc3_.type == param2)
            {
               _loc4_ = FightData.instance.applicationDomain.getDefinition(_loc3_.mc) as Class;
               return new _loc4_() as MovieClip;
            }
         }
         return null;
      }
   }
}

