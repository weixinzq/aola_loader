package mmo.petfightnew.common
{
   import mmo.common.member.MemberManager;
   import mmo.interfaces.material.item.IItemService;
   import mmo.interfaces.material.item.Item;
   import mmo.interfaces.material.item.UserItem;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.play.petfight.common.config.FiltItemConfig;
   
   public class FightItemData
   {
      
      private static var _instance:FightItemData;
      
      private static const ITEMS:Array = [30,60,61,263,31,103,104,100,94,99,96];
      
      private static const CATCH_ITEMS:Array = [164,64,68,67,32,520];
      
      private var itemService:IItemService;
      
      private var items:Array;
      
      private var fightItems:Array;
      
      private var catchItems:Array;
      
      public function FightItemData()
      {
         super();
      }
      
      public static function get instance() : FightItemData
      {
         if(_instance == null)
         {
            _instance = new FightItemData();
         }
         return _instance;
      }
      
      public function init() : void
      {
         this.itemService = ServicePool.instance.getService(IItemService);
         this.items = this.itemService.getMyMaterials();
         this.fightItems = this.filterItem();
         this.fightItems = this.sort(ITEMS,this.fightItems);
         this.catchItems = this.filterCatchItems();
         this.catchItems = this.sort(CATCH_ITEMS,this.catchItems);
      }
      
      public function get myFightItems() : Array
      {
         return this.fightItems;
      }
      
      public function get myCatchItems() : Array
      {
         return this.catchItems;
      }
      
      public function useItem(param1:int, param2:int) : Boolean
      {
         var _loc4_:Object = null;
         var _loc5_:int = 0;
         if(this.fightItems.length <= 0)
         {
            return false;
         }
         var _loc3_:int = 0;
         while(_loc3_ < this.fightItems.length)
         {
            _loc4_ = this.fightItems[_loc3_];
            _loc5_ = _loc4_.qt - param2;
            if(param1 == _loc4_.id && _loc5_ >= 0)
            {
               if(_loc5_ == 0)
               {
                  this.fightItems.splice(_loc3_,1);
               }
               else
               {
                  this.fightItems[_loc3_] = {
                     "id":param1,
                     "qt":_loc5_
                  };
               }
               return true;
            }
            _loc3_++;
         }
         return false;
      }
      
      public function useCatchItem(param1:int, param2:int) : Boolean
      {
         var _loc4_:Object = null;
         var _loc5_:int = 0;
         if(this.catchItems.length <= 0)
         {
            return false;
         }
         var _loc3_:int = 0;
         while(_loc3_ < this.catchItems.length)
         {
            _loc4_ = this.catchItems[_loc3_];
            _loc5_ = _loc4_.qt - param2;
            if(param1 == _loc4_.id && _loc5_ >= 0)
            {
               if(_loc5_ == 0)
               {
                  this.catchItems.splice(_loc3_,1);
               }
               else
               {
                  this.catchItems[_loc3_] = {
                     "id":param1,
                     "qt":_loc5_
                  };
               }
               return true;
            }
            _loc3_++;
         }
         return false;
      }
      
      public function dispose() : void
      {
         _instance = null;
      }
      
      private function filterItem() : Array
      {
         var _loc3_:UserItem = null;
         var _loc4_:Item = null;
         var _loc5_:int = 0;
         var _loc6_:Object = null;
         var _loc1_:Array = [];
         var _loc2_:int = 0;
         while(_loc2_ < this.items.length)
         {
            _loc3_ = this.items[_loc2_];
            _loc4_ = Item(_loc3_.material);
            if(_loc4_.type == 5 || _loc4_.type == 6 || _loc4_.type == 12)
            {
               _loc5_ = int(_loc3_.materialId);
               if(CATCH_ITEMS.indexOf(_loc5_) == -1)
               {
                  if(!this.checkIsFiltItem(_loc5_))
                  {
                     if(!(Boolean(_loc4_.vip) && !MemberManager.instance.isMember()))
                     {
                        if(_loc3_.quantity > 0)
                        {
                           _loc6_ = {
                              "id":_loc5_,
                              "qt":_loc3_.quantity
                           };
                           _loc1_.push(_loc6_);
                        }
                     }
                  }
               }
            }
            _loc2_++;
         }
         return _loc1_;
      }
      
      private function checkIsFiltItem(param1:int) : Boolean
      {
         var _loc5_:PlayerBattleInfo = null;
         var _loc6_:PetBriefInfo = null;
         var _loc7_:int = 0;
         var _loc8_:Array = null;
         var _loc2_:Array = FightData.instance.opponents;
         var _loc3_:Boolean = false;
         var _loc4_:int = 0;
         while(_loc4_ < _loc2_.length)
         {
            _loc5_ = _loc2_[_loc4_] as PlayerBattleInfo;
            _loc6_ = _loc5_.myPets[0] as PetBriefInfo;
            _loc7_ = int(_loc6_.raceId);
            _loc8_ = FiltItemConfig.filtItemMap[_loc7_];
            if(_loc8_ != null && _loc8_.indexOf(param1) != -1)
            {
               _loc3_ = true;
               break;
            }
            _loc4_++;
         }
         return _loc3_;
      }
      
      private function filterCatchItems() : Array
      {
         var _loc3_:UserItem = null;
         var _loc4_:Item = null;
         var _loc5_:int = 0;
         var _loc6_:Object = null;
         var _loc1_:Array = [];
         var _loc2_:int = 0;
         while(_loc2_ < this.items.length)
         {
            _loc3_ = this.items[_loc2_];
            _loc4_ = Item(_loc3_.material);
            if(_loc4_.type == 6)
            {
               _loc5_ = int(_loc3_.materialId);
               if(CATCH_ITEMS.indexOf(_loc5_) != -1)
               {
                  _loc6_ = {
                     "id":_loc5_,
                     "qt":_loc3_.quantity
                  };
                  _loc1_.push(_loc6_);
               }
            }
            _loc2_++;
         }
         return _loc1_;
      }
      
      private function sort(param1:Array, param2:Array) : Array
      {
         var _loc6_:int = 0;
         var _loc3_:Array = [];
         var _loc4_:int = int(param1.length);
         var _loc5_:int = 0;
         while(_loc5_ < _loc4_)
         {
            _loc6_ = int(param2.length - 1);
            while(_loc6_ >= 0)
            {
               if(param1[_loc5_] == param2[_loc6_].id)
               {
                  _loc3_.push(param2[_loc6_]);
                  param2.splice(_loc6_,1);
                  break;
               }
               _loc6_--;
            }
            _loc5_++;
         }
         return _loc3_.concat(param2);
      }
   }
}

