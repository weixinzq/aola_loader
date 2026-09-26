package mmo.petpackage.panel.inclusion
{
   import com.adobe.utils.ArrayUtil;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.miraclepet.IMiraclePetDataService;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.pm.operation.IPMSkillInfo;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petpackage.panel.inclusion.petdetailinfo.MiraclePetSkillComponent;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol1280")]
   public class MiraclePetAllSkillComponent extends Sprite
   {
      
      public var btnupgradeskill:SimpleButton;
      
      public var mpsc0:MiraclePetSkillComponent;
      
      public var mpsc1:MiraclePetSkillComponent;
      
      public var mpsc2:MiraclePetSkillComponent;
      
      public function MiraclePetAllSkillComponent()
      {
         super();
      }
      
      public function refresh(param1:int, param2:Array) : void
      {
         var _loc6_:MiraclePetSkillComponent = null;
         param2 = this.orderSkill(param1,param2);
         var _loc3_:Array = this.addPassiveSkill(param1,param2);
         var _loc4_:int = 0;
         while(_loc4_ < 3)
         {
            _loc6_ = this.getChildByName("mpsc" + _loc4_) as MiraclePetSkillComponent;
            _loc6_.refresh(param1,_loc4_,_loc3_[_loc4_],_loc4_ == 2);
            _loc4_++;
         }
         var _loc5_:IMiraclePetDataService = ServiceContainer.getService(IMiraclePetDataService) as IMiraclePetDataService;
         this.btnupgradeskill.visible = false;
      }
      
      private function orderSkill(param1:int, param2:Array) : Array
      {
         var _loc7_:IPMSkillInfo = null;
         var _loc8_:int = 0;
         var _loc3_:Array = [];
         var _loc4_:IMiraclePetDataService = ServiceContainer.getService(IMiraclePetDataService) as IMiraclePetDataService;
         var _loc5_:IPMService = ServiceContainer.getService(IPMService) as IPMService;
         var _loc6_:Vector.<IPMSkillInfo> = _loc5_.getOperationPM(param1).getCommonSkillList();
         for each(_loc7_ in _loc6_)
         {
            _loc8_ = 0;
            while(_loc8_ < param2.length)
            {
               if(_loc7_.skillId == (param2[_loc8_] as SkillInfo).id)
               {
                  _loc3_.push(param2[_loc8_]);
               }
               _loc8_++;
            }
         }
         return _loc3_;
      }
      
      private function addPassiveSkill(param1:*, param2:Array) : Array
      {
         var _loc3_:IMiraclePetDataService = ServiceContainer.getService(IMiraclePetDataService) as IMiraclePetDataService;
         var _loc4_:int = int(_loc3_.getMiraclePetInfo(param1).passiveSkillIdList[0]);
         var _loc5_:IPMService = ServiceContainer.getService(IPMService) as IPMService;
         var _loc6_:String = _loc5_.customData.pmSkillMap.getSkill(_loc4_).cnName;
         var _loc7_:SkillInfo = new SkillInfo();
         _loc7_.parseInfo({
            "pp":"0/0",
            "ssi":2,
            "used":true,
            "id":_loc4_,
            "name":_loc6_
         });
         var _loc8_:Array = ArrayUtil.copyArray(param2);
         _loc8_.push(_loc7_);
         return _loc8_;
      }
      
      public function dispose() : void
      {
         var _loc2_:MiraclePetSkillComponent = null;
         var _loc1_:int = 0;
         while(_loc1_ < 3)
         {
            _loc2_ = this.getChildByName("mpsc" + _loc1_) as MiraclePetSkillComponent;
            _loc2_.dispose();
            _loc1_++;
         }
      }
   }
}

