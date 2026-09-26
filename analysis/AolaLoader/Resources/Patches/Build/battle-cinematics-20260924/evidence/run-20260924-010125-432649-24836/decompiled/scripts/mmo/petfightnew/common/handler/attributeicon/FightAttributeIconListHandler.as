package mmo.petfightnew.common.handler.attributeicon
{
   import flash.display.Sprite;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.manager.ServicePool;
   
   public class FightAttributeIconListHandler
   {
      
      private var _pmService:IPMService = ServicePool.instance.getService(IPMService);
      
      private var _container:Sprite;
      
      private var _cacheKey:String;
      
      private var _attributeIconList:Array = [];
      
      private var _raceId:int;
      
      private var _attribute1:int = -1;
      
      private var _attribute2:int = -1;
      
      public function FightAttributeIconListHandler(param1:Sprite, param2:String)
      {
         super();
         this._container = param1;
         this._cacheKey = param2;
         this.init();
      }
      
      private function init() : void
      {
         var _loc3_:Sprite = null;
         var _loc4_:Sprite = null;
         var _loc1_:int = 2;
         var _loc2_:int = 0;
         while(_loc2_ < _loc1_)
         {
            _loc3_ = this._container.getChildByName("mcIcon" + _loc2_) as Sprite;
            if(_loc3_ == null)
            {
               break;
            }
            _loc4_ = this._container.getChildByName("iconBg" + _loc2_) as Sprite;
            this._attributeIconList[_loc2_] = new FightAttributeIconHandler(_loc3_,this._cacheKey,_loc4_);
            _loc2_++;
         }
      }
      
      public function setAttribute(param1:int, param2:PetBriefInfo) : void
      {
         this._raceId = param1;
         var _loc3_:PMData = this._pmService.getOperationPM(param1).pmData;
         var _loc4_:int = int(_loc3_.pmAttribute);
         var _loc5_:int = int(_loc3_.pmAttribute2);
         if(param2.pmAttribute >= 0)
         {
            _loc4_ = int(param2.pmAttribute);
         }
         if(param2.pmAttribute2 >= 0)
         {
            _loc5_ = int(param2.pmAttribute2);
         }
         if(this._attribute1 == _loc4_ && this._attribute2 == _loc5_)
         {
            return;
         }
         this._attribute1 = _loc4_;
         this._attribute2 = _loc5_;
         if(_loc4_ == _loc5_)
         {
            this.setAttributeByIndex(0,_loc4_);
            this.setAttributeByIndex(1,-1);
         }
         else
         {
            this.setAttributeByIndex(0,_loc4_);
            this.setAttributeByIndex(1,_loc5_);
         }
      }
      
      private function setAttributeByIndex(param1:int, param2:int) : void
      {
         var _loc3_:FightAttributeIconHandler = this._attributeIconList[param1];
         if(param2 < 0)
         {
            _loc3_.setEmpty();
         }
         else
         {
            _loc3_.setIcon(param2);
         }
      }
      
      public function dispose() : void
      {
         var _loc1_:FightAttributeIconHandler = null;
         for each(_loc1_ in this._attributeIconList)
         {
            _loc1_.dispose();
         }
         this._attributeIconList = null;
      }
   }
}

