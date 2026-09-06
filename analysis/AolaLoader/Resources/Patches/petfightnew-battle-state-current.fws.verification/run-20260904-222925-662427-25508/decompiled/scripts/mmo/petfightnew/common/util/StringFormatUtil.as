package mmo.petfightnew.common.util
{
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.FightData;
   
   public class StringFormatUtil
   {
      
      private static var _instance:StringFormatUtil;
      
      private var _pmSvr:IPMService = ServiceContainer.getService(IPMService) as IPMService;
      
      private var reqId:int;
      
      public function StringFormatUtil()
      {
         super();
      }
      
      public static function get instance() : StringFormatUtil
      {
         if(_instance == null)
         {
            _instance = new StringFormatUtil();
         }
         return _instance;
      }
      
      public function dispose() : void
      {
         _instance = null;
      }
      
      public function formatStr(param1:String) : String
      {
         var _loc5_:String = null;
         var _loc6_:* = null;
         var _loc7_:String = null;
         var _loc8_:String = null;
         var _loc9_:String = null;
         var _loc10_:String = null;
         var _loc11_:String = null;
         var _loc12_:* = null;
         var _loc13_:String = null;
         var _loc14_:* = null;
         var _loc15_:String = null;
         var _loc16_:int = 0;
         var _loc17_:String = null;
         var _loc18_:int = 0;
         var _loc19_:PlayerBattleInfo = null;
         var _loc20_:Array = null;
         var _loc21_:int = 0;
         var _loc22_:String = null;
         this.reqId = this.reqId;
         param1 ||= "";
         var _loc2_:String = "";
         var _loc3_:Array = param1.split("。");
         var _loc4_:int = 0;
         for(; _loc4_ < _loc3_.length; _loc4_++)
         {
            _loc5_ = _loc3_[_loc4_];
            if(!(_loc5_ == "" || _loc5_ == null))
            {
               if(_loc5_.indexOf("\n") != -1)
               {
                  _loc5_ = _loc5_.replace(/\n/g," ");
               }
               _loc6_ = "";
               if(_loc5_.lastIndexOf("$") == _loc5_.length - 1)
               {
                  _loc15_ = _loc5_.substring(0,_loc5_.length - 1);
                  _loc16_ = int(_loc15_.lastIndexOf("$"));
                  if(_loc16_ != -1 && _loc16_ < _loc15_.length - 1)
                  {
                     _loc17_ = _loc15_.substring(_loc16_ + 1);
                     if(isNaN(Number(_loc17_)) == false)
                     {
                        _loc5_ = _loc5_.substring(0,_loc16_);
                        _loc6_ = "$" + _loc17_ + "$";
                     }
                  }
               }
               if(this.containsCriticalHit(_loc5_))
               {
                  _loc7_ = this.formatCriticalHit("会心一击！");
                  _loc18_ = int(_loc5_.indexOf("！"));
                  _loc5_ = _loc5_.substr(_loc18_ + 1);
               }
               if(this.hasPetName(_loc5_) && this.hasSkillName(_loc5_))
               {
                  _loc8_ = this.subStr("[","(",_loc5_);
                  _loc10_ = this.subStr("(",")",_loc5_);
                  for each(_loc19_ in FightData.instance.playerInfo)
                  {
                     if(_loc10_ == _loc19_.PMMasterId.toString())
                     {
                        if(_loc19_.locaId <= 5)
                        {
                           _loc8_ = this.formatMyPetName(_loc8_);
                           break;
                        }
                        _loc8_ = this.formatVsPetName(_loc8_);
                        break;
                     }
                  }
                  if(_loc8_.indexOf("color") == -1)
                  {
                     _loc8_ = this.formatMyPetName(_loc8_);
                  }
                  _loc11_ = this.formatPredicate(_loc13_ = this.subStr("]","<",_loc5_));
                  _loc20_ = this.subStr("<",">",_loc5_).split("#");
                  _loc9_ = _loc20_[0];
                  _loc21_ = parseInt(_loc20_[1]);
                  _loc22_ = _loc20_[2];
                  if(this._pmSvr.customData.pmSkillMap.getSkill(_loc21_) != null && this._pmSvr.customData.pmSkillMap.getSkill(_loc21_).newCnName == _loc9_)
                  {
                     _loc9_ = this.formatSkillName(_loc21_,_loc22_,_loc9_);
                  }
                  else
                  {
                     _loc9_ = this.formatItemName(_loc9_);
                  }
                  _loc12_ = "[" + this.subStr("[","]",_loc5_) + "]";
                  _loc14_ = "<" + this.subStr("<",">",_loc5_) + ">";
                  _loc5_ = _loc5_.replace(_loc12_,_loc8_);
                  _loc5_ = _loc5_.replace(_loc14_,_loc9_);
                  _loc5_ = _loc5_.replace(_loc13_,_loc11_);
               }
               else if(this.hasPetName(_loc5_))
               {
                  _loc8_ = this.subStr("[","(",_loc5_);
                  _loc10_ = this.subStr("(",")",_loc5_);
                  for each(_loc19_ in FightData.instance.playerInfo)
                  {
                     if(_loc10_ == _loc19_.PMMasterId.toString())
                     {
                        if(_loc19_.locaId <= 5)
                        {
                           _loc8_ = this.formatMyPetName(_loc8_);
                           break;
                        }
                        _loc8_ = this.formatVsPetName(_loc8_);
                        break;
                     }
                  }
                  if(_loc8_.indexOf("color") == -1)
                  {
                     _loc8_ = this.formatMyPetName(_loc8_);
                  }
                  _loc11_ = this.formatPredicate(_loc13_ = _loc5_.substr(_loc5_.indexOf("]") + 1));
                  _loc12_ = "[" + this.subStr("[","]",_loc5_) + "]";
                  _loc5_ = _loc5_.replace(_loc12_,_loc8_);
                  _loc5_ = _loc5_.replace(_loc13_,_loc11_);
               }
               else
               {
                  if(_loc5_ == "攻击有效")
                  {
                     _loc5_ = this.formatAttEffective(_loc5_);
                     _loc2_ += _loc5_;
                     continue;
                  }
                  if(_loc5_ == "攻击强效")
                  {
                     _loc5_ = this.formatAttStrong(_loc5_);
                     _loc2_ += _loc5_;
                     continue;
                  }
                  if(_loc5_ == "攻击微弱")
                  {
                     _loc5_ = this.formatPredicate(_loc5_);
                     _loc2_ += _loc5_;
                     continue;
                  }
                  if(_loc5_ == "攻击无效")
                  {
                     _loc5_ = this.formatAttVain(_loc5_);
                     _loc2_ += _loc5_;
                     continue;
                  }
                  _loc5_ = this.formatPredicate(_loc5_);
               }
               _loc5_ += _loc6_;
               if(_loc7_ != null)
               {
                  _loc2_ += "\n" + _loc7_ + "\n" + _loc5_;
               }
               else
               {
                  _loc2_ += "\n" + _loc5_;
               }
            }
         }
         return _loc2_;
      }
      
      private function containsCriticalHit(param1:String) : Boolean
      {
         var _loc2_:int = int(param1.indexOf("会心一击"));
         if(_loc2_ >= 0)
         {
            return true;
         }
         return false;
      }
      
      private function formatCriticalHit(param1:String) : String
      {
         var _loc2_:String = null;
         return "<font color = \'#FF0000\'> " + param1 + "</font>";
      }
      
      private function formatAttVain(param1:String) : String
      {
         var _loc2_:String = null;
         return "<font color = \'#CCCCCC\'> " + param1 + "</font>";
      }
      
      private function formatAttStrong(param1:String) : String
      {
         var _loc2_:String = null;
         return "<font color = \'#FF9900\'> " + "攻击克制" + "</font>";
      }
      
      private function formatAttEffective(param1:String) : String
      {
         var _loc2_:String = null;
         return "<font color = \'#FFFF00\'> " + param1 + "</font>";
      }
      
      private function formatMyPetName(param1:String) : String
      {
         var _loc2_:String = null;
         return "<font color = \'#00FF00\'> [" + param1 + "] </font>";
      }
      
      private function formatVsPetName(param1:String) : String
      {
         var _loc2_:String = null;
         return "<font color = \'#FF9900\'> [" + param1 + "] </font>";
      }
      
      private function formatPredicate(param1:String) : String
      {
         var _loc2_:String = null;
         return "<font color = \'#FFFFFF\'> " + param1 + "</font>";
      }
      
      private function formatSkillName(param1:int, param2:String, param3:String) : String
      {
         var _loc4_:String = null;
         return "<a href=\'event:" + param1 + "#" + param2 + "\'><u><font color = \'#65FFFF\'>" + param3 + "</font></u></a>";
      }
      
      private function formatItemName(param1:String) : String
      {
         return "<font color = \'#65FFFF\'>" + param1 + "</font>";
      }
      
      private function subStr(param1:String, param2:String, param3:String) : String
      {
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         _loc4_ = int(param3.indexOf(param1));
         _loc5_ = int(param3.indexOf(param2));
         return param3.substring(_loc4_ + 1,_loc5_);
      }
      
      private function hasPetName(param1:String) : Boolean
      {
         if(param1.indexOf("[") != -1 && param1.indexOf("]") != -1)
         {
            return true;
         }
         return false;
      }
      
      private function hasSkillName(param1:String) : Boolean
      {
         if(param1.indexOf("<") != -1 && param1.indexOf(">") != -1)
         {
            return true;
         }
         return false;
      }
   }
}

