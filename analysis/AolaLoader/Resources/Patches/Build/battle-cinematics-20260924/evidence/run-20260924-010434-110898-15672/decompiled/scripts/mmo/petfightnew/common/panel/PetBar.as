package mmo.petfightnew.common.panel
{
   import flash.text.TextField;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.data.PmInBagData;
   import mmo.petfightnew.common.util.StatusUtil;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol453")]
   public class PetBar extends UIPanelBase
   {
      
      private static const MAX_PET_NUM:int = 6;
      
      public var ph0:TextField;
      
      public var ph1:TextField;
      
      public var ph2:TextField;
      
      public var ph3:TextField;
      
      public var ph4:TextField;
      
      public var ph5:TextField;
      
      private var _myPets:Array = new Array();
      
      private var _petHolderList:Array = [];
      
      public function PetBar()
      {
         super();
         this._myPets = FightData.instance.myInfo.myAllPetList;
         this.init();
         this.update();
      }
      
      private function init() : void
      {
         var _loc2_:TextField = null;
         var _loc3_:PetHolder = null;
         var _loc4_:int = 0;
         var _loc1_:int = 0;
         while(_loc1_ < MAX_PET_NUM)
         {
            _loc2_ = getChildByName("ph" + _loc1_) as TextField;
            _loc2_.visible = false;
            if(_loc1_ < this._myPets.length)
            {
               _loc3_ = this._petHolderList[_loc1_] = new PetHolder();
               _loc3_.x = _loc2_.x;
               _loc3_.y = _loc2_.y;
               _loc4_ = this.getChildIndex(_loc2_);
               addChildAt(_loc3_,_loc4_);
            }
            _loc1_++;
         }
      }
      
      override public function update() : void
      {
         this.updatePetState(true);
      }
      
      override public function setNoClickIntoHandle() : void
      {
         this.updatePetState(false);
      }
      
      private function updatePetState(param1:Boolean) : void
      {
         var j:int;
         var raceIds:Array = null;
         var curHps:Array = null;
         var thePet:PetBriefInfo = null;
         var inBattleFieldPet:PetBriefInfo = null;
         var bagData:PmInBagData = null;
         var pbiTemp:PetBriefInfo = null;
         var holder:PetHolder = null;
         var icClickInto:Boolean = param1;
         var petInfoArray:Array = [];
         var hasPetCanSwitch:Boolean = false;
         var leastLockAlivePetIndex:int = -1;
         var leastLockCount:int = int.MAX_VALUE;
         var i:int = 0;
         while(i < this._petHolderList.length)
         {
            thePet = this._myPets[i];
            inBattleFieldPet = FightData.instance.myInfo.getInBattleFiledPet(thePet.id);
            if(inBattleFieldPet)
            {
               thePet = inBattleFieldPet;
               FightData.instance.myInfo.updateRealTimeRoleHpData(thePet.uqi,thePet.id,thePet);
            }
            else
            {
               bagData = FightData.instance.myInfo.getRealTimeRoleHpData(thePet.uqi,thePet.id);
               if(bagData)
               {
                  thePet.curHp = bagData.curHp;
                  thePet.maxHp = bagData.maxHp;
                  thePet.status = bagData.st;
                  thePet.updateLockRound(bagData.lockRound);
                  thePet.raceId = bagData.raceId;
                  thePet.setViewId(bagData.viewId);
                  thePet.name = bagData.name;
                  thePet.nickname = bagData.nickName == null || bagData.nickName == "" ? bagData.name : bagData.nickName;
                  thePet.pmAttribute = bagData.pmAttribute;
                  thePet.pmAttribute2 = bagData.pmAttribute2;
               }
            }
            if(icClickInto)
            {
               if(thePet.curHp > 0 && thePet.lockRound <= 0)
               {
                  hasPetCanSwitch = true;
               }
            }
            else if(!inBattleFieldPet && thePet.curHp > 0 && thePet.lockRound <= 0)
            {
               hasPetCanSwitch = true;
            }
            if(thePet.curHp > 0 && thePet.lockRound > 0)
            {
               if(leastLockCount > thePet.lockRound)
               {
                  leastLockAlivePetIndex = i;
                  leastLockCount = int(thePet.lockRound);
               }
            }
            if(!StatusUtil.getIsInShiKongFangZhuState(thePet))
            {
               petInfoArray.push(thePet);
            }
            i++;
         }
         if(!hasPetCanSwitch && leastLockAlivePetIndex >= 0)
         {
            pbiTemp = petInfoArray[leastLockAlivePetIndex] as PetBriefInfo;
            pbiTemp.updateLockRound(0);
         }
         j = 0;
         while(j < this._petHolderList.length)
         {
            holder = this._petHolderList[j];
            if(petInfoArray.length > j)
            {
               holder.setPet(petInfoArray[j]);
            }
            else
            {
               holder.setEmpty();
            }
            j++;
         }
         raceIds = [];
         curHps = [];
         petInfoArray.forEach(function(param1:PetBriefInfo, param2:int, param3:Array):void
         {
            raceIds[param2] = param1.raceId;
            curHps[param2] = param1.curHp;
         });
         CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.FIGHT_PET_OBJECT_UPDATE,{
            "raceIds":raceIds,
            "curHps":curHps,
            "petMcs":this._petHolderList
         }));
      }
      
      override public function dispose() : void
      {
         var _loc1_:PetHolder = null;
         for each(_loc1_ in this._petHolderList)
         {
            _loc1_.dispose();
         }
         this._petHolderList = null;
      }
   }
}

